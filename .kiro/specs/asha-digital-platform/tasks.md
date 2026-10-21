# Implementation Plan: ASHA Digital Platform

## Overview

This plan converts the ASHA Digital Platform design into 15 incremental coding tasks. Each task
produces a runnable, testable increment. Tasks build on each other sequentially within the mobile
and backend layers, with the React dashboards branching from the shared backend starting at Task 13.

Language choices from the design document:
- **Flutter 3.x (Dart)** — mobile app
- **FastAPI + Python 3.12** — backend
- **React 18 + TypeScript + TailwindCSS** — web dashboards

---

## Tasks

- [x] 1. Project scaffold and encrypted local database
  - [x] 1.1 Create Flutter project with Android target (minSdk 21) and directory structure
    - Scaffold `lib/` with the feature-slice structure from the design: `app/`, `core/`, `features/`, `shared/`
    - Add dependencies to `pubspec.yaml`: `drift`, `sqlcipher_flutter_libs`, `drift_flutter`, `riverpod_annotation`, `go_router`, `flutter_riverpod`, `local_auth`, `flutter_secure_storage`, `cryptography`, `uuid`, `path_provider`
    - Create `lib/core/database/app_database.dart` with a `DriftAppDatabase` class using `NativeDatabase.opened()` with SQLCipher
    - _Requirements: 1.2, 2.1_

  - [x] 1.2 Define all drift table schemas
    - Define tables in `lib/core/database/tables/`: `Households`, `Members`, `ConsentRecords`, `ClinicalEncounters`, `ClinicalObservations`, `TriageResults`, `ReferralRecords`, `VisitSchedules`, `IncentiveEvents`, `IncentiveClaims`, `SyncQueue`, `RuleVersions`, `AuditLog`, `Drafts`, `StockItems`, `StockTransactions`, `FacilityDirectory`, `LearningProgress`, `DeviceProfiles`
    - Add FTS5 virtual table `members_fts` covering `member_id`, `name`, `name_phonetic`, `abha_id`, `rch_id`, `phone`, `village`
    - Add all key indexes listed in the design (sync_queue pending partial index, visit_schedules due_date, encounters by member+program, incentive_events unique idempotency key, audit_log chain)
    - Run `dart run build_runner build` to generate DAOs and companion classes
    - _Requirements: 1.2, 1.6, 4.2, 4.7, 33.1_

  - [-] 1.3 Implement PBKDF2 key derivation and SQLCipher key management
    - Create `lib/core/security/key_manager.dart`: `deriveKey(pin, salt)` using PBKDF2 with 100,000 SHA-256 iterations producing a 32-byte key
    - Store salt in `AndroidKeystore`-backed `EncryptedSharedPreferences` via `flutter_secure_storage`
    - Implement `changePin(oldPin, newPin, db)` using `PRAGMA rekey`
    - _Requirements: 2.1, 44.1_

  - [x] 1.4 Implement PIN/biometric authentication service
    - Create `lib/core/security/auth_service.dart`: PIN hash storage (bcrypt), PIN entry flow, biometric via `local_auth`, 3-consecutive-biometric-failure fallback to PIN
    - Implement configurable lockout: starts at 30 s, doubles per failed attempt, cap 10 min; require OTP after final attempt
    - Create `lib/core/security/remote_wipe.dart` stub (wired in Task 2)
    - _Requirements: 2.1, 2.4_

  - [x] 1.5 Implement idle-lock and recent-apps privacy
    - Add `AppLifecycleObserver` that starts an idle timer on background; lock screen and call `FLAG_SECURE` + clear recent-apps thumbnail on timeout
    - Configurable timeout 1–30 min (default 2 min) stored in settings table
    - _Requirements: 2.2_

  - [x] 1.6 Implement draft recovery service
    - Create `lib/core/database/daos/drafts_dao.dart`: `saveDraft(formType, memberId, partialDataJson)`, `getDraft(formType, memberId)`, `deleteDraft(...)`
    - Trigger save on every form field change via a debounced Riverpod state listener
    - On app launch, query for existing drafts and present resume prompt
    - _Requirements: 1.3_

  - [x] 1.7 Scaffold Riverpod state layer and go_router navigation
    - Define `appDatabase`, `triageEngine`, `syncEngine`, `authService` as `@Riverpod(keepAlive: true)` providers in `lib/shared/providers/`
    - Create `lib/app/router.dart` with all route groups: `/`, `/home`, `/household/:id`, `/visit/:id`, `/triage`, `/referral/:id`, `/programs/*`, `/learning`, `/incentives`, `/af/*`, `/settings`
    - Add role-based redirect guards for restricted routes
    - Create placeholder screens for each top-level route (enough to navigate without errors)
    - _Requirements: 2.3_

  - [x] 1.8 Write unit tests for key derivation, PIN auth, and draft recovery
    - Test: `deriveKey` produces same output for same (pin, salt)
    - Test: `deriveKey` produces different output for different PINs on same salt
    - Test: lockout timer doubles correctly through sequence of failed attempts
    - Test: `saveDraft` followed by force-close emulation and `getDraft` returns same state (idempotency)
    - _Requirements: 1.3, 2.1_

  - [x] 1.9 Write property test for draft recovery idempotence (Property 2)
    - **Property 2: Draft Recovery Idempotence**
    - Generate arbitrary partial form data; apply `saveDraft` N times; verify `getDraft` always returns same state with no duplicate draft records
    - **Validates: Requirements 1.3**

- [x] 2. BitChat-style sync engine and backend scaffold
  - [-] 2.1 Create FastAPI project skeleton with async SQLAlchemy and PostgreSQL
    - Scaffold `backend/` with `main.py`, `api/v1/`, `models/db/`, `models/schemas/`, `services/`, `workers/`, `db/`, `core/`
    - Add dependencies to `requirements.txt`: `fastapi`, `uvicorn[standard]`, `sqlalchemy[asyncio]`, `asyncpg`, `alembic`, `pydantic-settings`, `python-jose[cryptography]`, `passlib[bcrypt]`, `celery[redis]`, `gzip`, `fhir.resources`
    - Create `db/session.py` with async SQLAlchemy engine and session factory
    - Production deployment note: Render uses the Supabase shared IPv4 Session
      pooler URI (port 5432); the direct `db.<project-ref>.supabase.co` endpoint
      is IPv6-only on Supabase projects without the IPv4 add-on.
    - Write Alembic initial migration mirroring all mobile tables plus server-side columns (`worker_id`, `server_received_at`, `server_seq`, `state_code`, `district_code`, `block_code`) and `conflict_review`, `pending_merge` tables
    - _Requirements: 31.1, 32.1_

  - [-] 2.2 Implement JWT authentication endpoints
    - Create `api/v1/auth.py`: `POST /auth/login` (ASHA ID + PIN/OTP + device_id → access_token 15 min + refresh_token 30 days + offline_credential 7 days), `POST /auth/refresh`, `POST /auth/revoke` (admin only)
    - JWT payload includes `sub`, `role`, `state_code`, `district_code`, `block_code`, `area_villages[]`
    - Implement offline credential as bcrypt hash of `(worker_id + device_id + expiry)` stored in `flutter_secure_storage` on device
    - _Requirements: 2.1, 2.6, 2.7_

  - [x] 2.3 Implement multi-tenant row-level isolation middleware
    - Create `core/multi_tenant.py`: SQLAlchemy event listener `do_orm_execute` that appends area filter for ASHA and AF roles based on JWT claims
    - Wire middleware into FastAPI app lifespan in `main.py`
    - _Requirements: 2.3_

  - [x] 2.4 Build sync push endpoint with idempotent upserts and conflict resolution
    - Create `api/v1/sync.py`: `POST /sync/push` — decompress gzip body, detect duplicate `batch_id`, call `sync_service.apply_batch()`
    - Implement `services/sync_service.py`: field-level last-write-wins using `device_timestamp`, clinical conflict storage with provenance, insert into `conflict_review` on same-field concurrent edits, fuzzy duplicate detection queued to `pending_merge`
    - Record both `device_timestamp` and `server_received_at` on every event
    - Return `SyncPushResponse` with `synced[]`, `conflicts[]`, `server_watermarks`
    - _Requirements: 31.2, 32.2, 32.3_

  - [x] 2.5 Build sync pull endpoint with watermark-based delta delivery
    - Create `GET /sync/pull?worker_id&watermarks={...}` in `api/v1/sync.py`
    - Query all tables for records with `server_seq > watermark[table]` scoped to the worker's area
    - Return compressed delta with updated watermarks and `has_more` flag
    - _Requirements: 31.1_

  - [x] 2.6 Implement Flutter sync engine with priority queue and WorkManager
    - Create `lib/core/sync/sync_engine.dart`: enqueue records into `sync_queue` table on every write with priority tags (P1–P4)
    - Create `lib/core/sync/sync_worker.dart`: WorkManager Dart entry point; drain top-N pending queue entries ordered by `(priority ASC, created_at ASC)`; build gzip delta payload; POST to `/sync/push`; update `sync_status` per record
    - Implement exponential backoff: 30 s → 60 s → 120 s → 300 s max; schedule periodic sync every 15 min and expedited one-shot for P1 records
    - Implement WorkManager constraints: `networkType: connected`, `requiresBatteryNotLow: true`, `requiresStorageNotLow: true`
    - Create `lib/core/sync/conflict_resolver.dart`: merge server response conflicts into Local_Store
    - _Requirements: 31.1, 31.2, 31.3, 31.6_

  - [x] 2.7 Implement SMS fallback text generation for Red referrals
    - Create `lib/core/sync/sms_fallback.dart`: `generateReferralSMS(referral) → String` producing a ≤160-char compact summary (member_id_short, age, sex, flag, facility, ASHA name+phone, ref# short)
    - Expose as an Android `tel:` and SMS intent action in the referral workflow
    - _Requirements: 31.5_

  - [-] 2.8 Implement remote wipe flow
    - Wire `lib/core/security/remote_wipe.dart`: on FCM silent push with `type: revocation` or on `/auth/refresh` returning 401, call `wipe()` which DROPs all drift tables, deletes the SQLCipher database file, clears `flutter_secure_storage`, and returns to the initial setup screen
    - _Requirements: 2.5_

  - [-] 2.9 Implement certificate pinning
    - Configure `http_certificate_pinning` with SHA-256 fingerprints for production API domains
    - On mismatch, block request and show offline-capable fallback message
    - _Requirements: 44.1_

  - [x]* 2.10 Write integration tests for sync push/pull round-trip and conflict resolution
    - Test: create record on device → sync push → verify on backend DB → sync pull to second device → verify field values match
    - Test: two concurrent offline edits to same field → push both → verify both values retained in `conflict_review` with provenance
    - Test: push same batch twice (retry simulation) → verify DB state identical after second push
    - _Requirements: 31.2, 32.2, 32.3_

  - [x]* 2.11 Write property test for sync idempotence (Property 6) and priority ordering (Property 7)
    - **Property 6: Sync Idempotence**
    - Generate arbitrary sync batches; apply twice; assert DB state identical after first and second application
    - **Property 7: Sync Priority Ordering**
    - Generate mixed-priority queues; assert no lower-priority record dispatched before all higher-priority records are acknowledged
    - **Validates: Requirements 31.1, 31.2**

- [x] 3. Checkpoint — verify Tasks 1 and 2 integrate correctly
  - Ensure all unit and integration tests pass. Launch the Flutter app: it should present a PIN setup screen, create an encrypted SQLite DB, and reach the placeholder home screen. Ensure all tests pass, ask the user if questions arise.

- [x] 4. Multilingual UI framework and voice input
  - [x] 4.1 Set up flutter_localizations and ARB files for 12 languages
    - Add `flutter_localizations`, `intl` to `pubspec.yaml`; configure `supportedLocales` in `MaterialApp`
    - Create `lib/core/l10n/arb/` with base `app_en.arb` and stubs for hi, mr, bn, te, ml, ta, kn, or, gu, pa, as
    - Populate ARB files with keys for all screen labels, audio prompt strings, clinical terms, and triage result messages
    - Implement runtime language switching via a `languageProvider` (Riverpod) that updates `MaterialApp.locale` and persists selection to settings — no data loss on switch
    - _Requirements: 3.1, 3.6_

  - [x] 4.2 Integrate Vosk ASR for on-device speech recognition
    - Add `vosk_flutter` to `pubspec.yaml`; create `lib/core/voice/vosk_service.dart`
    - Implement `VoskService`: lazy model initialisation on first microphone tap, lifecycle dispose on navigation away, RAM-based model selection (40 MB full / 15 MB compressed / tap-only fallback at <1 GB)
    - Implement grammar constraints for closed-vocabulary fields (yes/no, enumerations, numeric input) via Vosk FST grammar
    - Implement ambient noise detection via microphone RMS; surface `TooNoisyDialog` offering tap entry
    - _Requirements: 6.1, 6.2, 6.5, 6.7_

  - [x] 4.3 Implement Lexicon service and confidence-threshold confirmation
    - Create `lib/core/voice/lexicon_service.dart`: load Lexicon JSON from assets, expose `lookup(spokenTerm, language) → canonicalConcept`
    - Implement confidence check: if Vosk confidence < 0.7, play back interpreted value via TTS and require explicit confirm/reject before accepting
    - Implement idempotent `canonicalise(term)`: applying twice returns same result
    - _Requirements: 6.2, 6.3, 6.6_

  - [x] 4.4 Implement TTS audio output service
    - Create `lib/core/voice/tts_service.dart`: wrap `flutter_tts`; load bundled pre-recorded human voice clips where available; fall back to on-device synthesis
    - Wire tap-to-hear audio prompt widget available on every screen
    - Implement step-by-step audio guidance sequences for clinical procedures (breath counting, MUAC, ORS preparation)
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [x] 4.5 Implement one-question-per-screen form framework with accessibility
    - Create `lib/shared/widgets/clinical_question_scaffold.dart`: one question per screen, 48×48 dp minimum touch targets, WCAG AA high-contrast colours
    - Add voice input button wired to `VoskService` and `LexiconService` on every form field
    - Implement OTA string bundle delivery: backend serves updated ARB bundles; app applies on next sync without APK update
    - _Requirements: 3.2, 3.3, 3.4, 3.6, 49.1, 49.4_

  - [x] 4.6 Implement optional Vosk model download manager
    - Create `lib/core/voice/model_manager.dart`: each language model is an independently downloadable SHA-256-verified `.zip`; store in `getApplicationSupportDirectory()`; exclude from cloud backup; support install/remove without APK update
    - Wire Hindi model as default post-install download (deferred to Wi-Fi if data-cost control mode on)
    - _Requirements: 6.9_

  - [x] 4.7 Write unit tests for Lexicon lookup, noise detection, and TTS fallback
    - Test: `lookup` returns correct canonical concept for each language
    - Test: `lookup` on an already-canonical term returns the same term (idempotence)
    - Test: noise RMS above threshold triggers tap-only offer
    - Test: Vosk confidence below 0.7 triggers read-back confirmation flow
    - _Requirements: 6.2, 6.3, 6.5_

  - [x] 4.8 Write property tests for Lexicon idempotence (Property 13)
    - **Property 13: Lexicon Normalisation Idempotence**
    - For arbitrary string inputs, assert `normalise(normalise(term)) == normalise(term)` across all supported languages
    - **Validates: Requirements 6.2, 6.6**

- [x] 5. Household and beneficiary registry with offline search
  - [x] 5.1 Implement household and member DAOs and repository
    - Create `lib/features/household/data/household_dao.dart` and `member_dao.dart` with drift DAOs
    - Create `lib/features/household/data/household_repository.dart`: wraps DAOs, generates UUID v4 on device before `INSERT`, enqueues to `sync_queue` after every write
    - _Requirements: 4.1, 4.2_

  - [x] 5.2 Implement household registration and member list screens
    - Create `lib/features/household/presentation/household_form_screen.dart`: capture village/hamlet/head-of-household/member list/DOB/sex/relationships/social category/BPL/contact phone; all fields except name and village individually skippable
    - Create `lib/features/household/presentation/household_list_screen.dart`: list all households with hamlet grouping
    - _Requirements: 4.1_

  - [x] 5.3 Implement fuzzy duplicate detection
    - Create `lib/features/household/domain/duplicate_detector.dart`: Levenshtein distance on name + phonetic Soundex normalisation, cross-checked with DOB + household + phone; configurable threshold
    - On save, query FTS5 for candidates, compute scores, present merge/link/continue dialog if above threshold
    - _Requirements: 4.3_

  - [x] 5.4 Implement FTS5 beneficiary search
    - Create `members_fts` virtual table population trigger in drift migrations (after insert/update on `members`)
    - Implement `MemberSearchRepository.search(query)`: SQLite `MATCH` query on `members_fts` with partial prefix; returns matches within ASHA's area only
    - Wire to a search bar accessible from the home screen; all lookups operate offline
    - _Requirements: 4.7_

  - [x] 5.5 Implement beneficiary timeline screen
    - Create `lib/features/household/presentation/beneficiary_timeline_screen.dart`: reverse-chronological stream of encounters, triage results, referrals, immunizations, and incentive events for a member, sourced via `StreamProvider` from drift
    - _Requirements: 4.4_

  - [x] 5.6 Implement life event recording and task suppression
    - Add `recordLifeEvent(memberId, eventType, timestamp)` to `MemberRepository`; update `lifecycle_status`; cancel open `visit_schedules` records for the affected member where applicable
    - Life events: birth, death, migration, marriage, household transfer
    - _Requirements: 4.5_

  - [x] 5.7 Implement consent workflow
    - Create `lib/features/household/domain/consent_service.dart`: present plain-language audio consent screen; on grant, write `ConsentRecord` with `signature_hash = SHA256(memberId + consentVersion + timestamp + ashaId)`; emergency-only mode if declined (minimum legal fields only); propagate withdrawal to sync queue immediately
    - Implement guardian consent branch for minors and incapacitated persons
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [x] 5.8 Implement ABHA offline capture and hand-over workflow
    - Capture ABHA details offline; set `abha_linked: false`; on sync, backend triggers ABDM verification via sandbox API and syncs back verified status
    - Create hand-over workflow: transfer households + open tasks to designated successor ASHA with full `audit_log` entries (transferring worker, receiving worker, timestamp, reason)
    - _Requirements: 4.6, 4.8_

  - [x] 5.9 Write unit tests for duplicate detection, FTS5 search, and consent tamper evidence
    - Test: two identical (name, DOB, household) records always score above threshold
    - Test: Unicode NFC-normalised names match correctly
    - Test: FTS5 search returns partial-prefix matches
    - Test: `ConsentRecord.signature_hash` changes when any input field changes
    - _Requirements: 4.3, 4.7, 5.2_

  - [x] 5.10 Write property test for duplicate detection invariant (Property 9)
    - **Property 9: Duplicate Beneficiary Detection Invariant**
    - For any two records with identical name (NFC-normalised), same DOB, same household, assert `matchScore >= configuredThreshold` regardless of field-comparison order
    - **Validates: Requirements 4.3**

- [x] 6. On-device triage engine (Red / Yellow / Green)
  - [x] 6.1 Implement the pure Dart triage engine
    - Create `lib/core/triage/triage_engine.dart`: `evaluate(TriageInputs inputs, RuleSet ruleSet) → TriageResult` — pure function, no I/O, no side effects
    - Implement condition-tree evaluator supporting all operators: `gt`, `lt`, `gte`, `lte`, `eq`, `neq`, `in`, `not_in`, `and`, `or`, `not`, `present`, `absent`
    - Age-band routing: `INFANT_0_2M`, `CHILD_2M_5Y`, `ADOLESCENT`, `ADULT`, `PREGNANT`
    - Evaluate all rules (no short-circuit); collect all findings; return highest severity flag plus full finding list
    - Missing-field handling: if ASHA proceeds without required inputs, escalate severity one level (cap at RED), list each missing item explicitly
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.8_

  - [x] 6.2 Implement rule versioning, OTA bundle delivery, and integrity verification
    - Create `lib/core/triage/rule_loader.dart`: download signed rule bundle from `/api/v1/rules/latest`, verify SHA-256 hash, write to `rule_versions` table, activate only after full download and hash verification, retain previous version for rollback
    - Store active `RuleSet` in memory after first load; sub-10ms access
    - Implement `GET /api/v1/rules/latest` and `GET /api/v1/rules/{version}/bundle.json.gz` on backend in `api/v1/rules.py`
    - Add backend `rule_service.py`: JSON bundle packaging with clinical lead approval gate, automated test-suite execution (block release on any failure), semantic versioning, state overlay rules as additive/restrictive layer on national base
    - _Requirements: 9.2, 9.3, 9.4, 9.5, 9.6, 9.7_

  - [x] 6.3 Implement ML component hook and override recording
    - Add `MLTriageContribution` to `TriageResult`; when present, enforce `final_flag.severity >= rule_flag.severity` (ML can only raise, never lower); display ML contribution as separately labelled item with feature weights
    - Implement triage override: up/down, require reason 10–500 chars (text or voice note via `VoskService`), write `TriageOverride` to encounter record — store both engine output and override value
    - Add "decision support" disclaimer label; exclude "diagnosis" and "prescription" from all language ARB files
    - _Requirements: 8.6, 8.7, 8.9_

  - [x] 6.4 Wire triage engine into clinical encounter flow
    - On explicit form submit, call `triageEngine.evaluate()`; guarantee < 1 s on 2 GB RAM Android 9 (benchmark in CI)
    - On RED flag, auto-open referral workflow (Task 7)
    - Speak triage result via `TtsService` (colour + primary reason + action)
    - Capture optional triage image and voice evidence; gzip-compress and store them in the encrypted sync outbox, then persist the packet and attachments on the backend
    - _Requirements: 8.1, 8.5, 8.6, 46.1, 46.2_

  - [x] 6.5 Write unit tests for triage determinism, ML monotonicity, and missing-input escalation
    - Test: same inputs + same rule version always produces same output
    - Test: final severity ≥ rule severity when ML component present
    - Test: replacing absent field with normal value never increases severity
    - Test: replacing absent field with abnormal value never decreases severity
    - Test: malformed input produces conservative flag with "input error" annotation, not crash
    - _Requirements: 8.4, 8.8, 8.9_

  - [x] 6.6 Write property tests for triage determinism and monotonicity (Properties 3, 4, 5)
    - **Property 3: Triage Engine Determinism**
    - For arbitrary (inputs, ruleVersion), assert `evaluate(inputs) == evaluate(inputs)` across N iterations
    - **Property 4: Triage Severity Monotonicity (ML)**
    - For arbitrary (rule_flag, ml_flag), assert `final_flag.severity >= rule_flag.severity`
    - **Property 5: Missing-Input Escalation Monotonicity**
    - For arbitrary inputs with absent fields, assert adding normal value never raises severity; adding abnormal value never lowers severity
    - **Validates: Requirements 8.4, 8.8, 8.9**

  - [x] 6.7 Write property test for rule-set serialisation round-trip (Property 18)
    - **Property 18: Rule Set Serialisation Round-Trip**
    - For arbitrary `RuleSet` values, assert `deserialise(serialise(ruleSet)) == ruleSet` (all condition trees, thresholds, citations preserved)
    - **Validates: Requirements 9.1**

- [x] 7. Checkpoint — verify triage engine correctness
  - Run the full triage property test suite (Properties 3, 4, 5). Launch the app, register a test household, open a triage form, submit clinical inputs, and verify a RED/YELLOW/GREEN result appears in < 1 s with an audio readout. Ensure all tests pass, ask the user if questions arise.

- [x] 8. Referral notes and referral lifecycle
  - [x] 8.1 Implement structured referral note generation
    - Create `lib/features/referral/domain/referral_note_generator.dart`: assemble structured note (patient identifiers, age/sex, key symptoms+vitals, triage flag+triggering reasons, actions taken, date/time, ASHA name+phone)
    - Notes generated fully offline; bilingual (local language + optional English toggle)
    - _Requirements: 10.1, 10.7_

  - [x] 8.2 Implement offline facility matching
    - Create `lib/features/referral/domain/facility_matcher.dart`: query `facility_directory` table; filter by care level matching triage severity; compute Haversine distance from ASHA's registered area; return shortest-distance qualifying facility with contact phone and available services
    - _Requirements: 10.3, 10.5_

  - [x] 8.3 Implement referral output formats
    - Wire `lib/core/pdf/pdf_generator.dart` to render referral note as print-ready PDF using the `pdf` Dart package (thermal + standard printer layouts)
    - Add share actions: PDF, image (Flutter `toImage`), SMS text (≤160 chars via `sms_fallback.dart`), QR code (`qr_flutter`), WhatsApp deep-link (`https://wa.me/?text=...`)
    - One-tap emergency dial: 108, 102, locally configured contacts (offline `tel:` URI)
    - _Requirements: 10.2, 10.8_

  - [x] 8.4 Implement referral outcome feedback loop
    - Add `POST /api/v1/referrals/{id}/outcome` endpoint in `api/v1/referrals.py`; on receipt, push FCM notification to originating ASHA's device and to the supervising ANM/AF; update referral record status
    - Sync outcome back to ASHA's device via next pull; append to beneficiary timeline
    - _Requirements: 10.4, 10.5_

  - [x] 8.5 Implement non-arrival follow-up task generation
    - Backend Celery job `check_referral_arrival`: run every 30 min; for RED referrals with no arrival outcome after configurable window (default 24 h), create overdue follow-up task for ASHA and send alert to AF
    - _Requirements: 10.6_

  - [x]* 8.6 Write integration tests for full referral lifecycle
    - Test: RED triage → referral created → facility matched offline → PDF generated → sync to backend → outcome recorded at facility → outcome synced back to ASHA device → beneficiary timeline updated
    - Test: SMS fallback text is ≤ 160 characters for all supported languages
    - _Requirements: 10.1, 10.2, 10.4, 10.5_

- [x] 9. Core clinical programs — HBNC, HBYC, ANC/PNC
  - [x] 9.1 Implement HBNC visit scheduling and guided checklist
    - Create `lib/features/clinical_programs/hbnc/`: on delivery record, auto-generate `VisitSchedule` entries for days 1/3/7/14/21/28 (plus additional visits for LBW/sick newborns)
    - Guided checklist: feeding/weight/temperature/breathing rate/cord care/skin/eyes/activity/jaundice/hygiene/thermal care/maternal PNC status — each item a `ClinicalObservation`
    - Danger sign → immediate `TriageEngine.evaluate()` → RED + referral workflow
    - LBW (< 2.5 kg) or preterm → enrol in high-risk pathway + display KMC guidance on each visit screen
    - Missed visit window → mark overdue, reschedule within allowed window, notify AF on next sync
    - Maternal/newborn death → capture death review fields, generate AF/ANM/MO alert on sync
    - HBNC completion → write `IncentiveEvent` with `activityCode: HBNC_COMPLETE`
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7_

  - [x] 9.2 Implement HBYC visit scheduling and child development checklist
    - Create `lib/features/clinical_programs/hbyc/`: schedule visits at 3/6/9/12/15 months
    - Checklist: feeding practices/complementary feeding/immunization status/growth measurements/developmental milestones/illness interval/responsive-caregiving counselling
    - Delayed milestones → referral to Anganwadi/RBSK/DEIC with pre-populated reason
    - SAM at HBYC → auto-trigger nutrition pathway (Task 10)
    - Display pictorial storyboard cards + play audio caregiver messages
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

  - [x] 9.3 Implement ANC registration, schedule generation, and high-risk flagging
    - Create `lib/features/clinical_programs/anc_pnc/`: capture LMP, EDD, obstetric history (gravida/para/previous complications/previous C-section/stillbirths); link MCP card and RCH/ABHA identifiers
    - Auto-generate ANC schedule: contacts + TT/Td doses + IFA/calcium + ultrasound + labs; add each to `VisitSchedule`
    - High-risk criteria evaluated by `TriageEngine`: BP threshold / Hb threshold / age <18 or >35 / parity ≥4 / prior complications / bleeding / oedema / headache / reduced fetal movement → flag high-risk, show specific reasons
    - High-risk → increase visit frequency, sync alert to ANM/AF
    - Birth plan prompt at 34 weeks gestation: delivery facility / transport / escort / blood donor / savings / emergency contacts
    - Overdue ANC → overdue task + priority follow-up
    - Pregnancy end → trigger appropriate downstream pathway (PNC / HBNC / death review)
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7_

  - [x] 9.4 Implement PNC postnatal care flow
    - Postpartum checklist: bleeding/fever/BP/breast problems/wound healing/mood indicators/nutrition/contraception counselling offer
    - Maternal danger signs → RED + referral
    - PPD indicators → supportive counselling pathway + mental health referral
    - Institutional delivery confirmed → write `IncentiveEvent` with `activityCode: INSTITUTIONAL_DELIVERY_ESCORT`
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6_

  - [x] 9.5 Implement due list auto-generation from program events
    - Create `lib/features/due_list/domain/task_scheduler.dart`: after any visit completion, write the next `VisitSchedule` entry following the program protocol; evaluate urgency score = `clinical_risk_level × (1 / days_until_window_expiry)`
    - Due list home screen: today's tasks grouped (RED follow-ups → overdue → due today → upcoming) then by hamlet
    - Skip-reason capture from defined list; reschedule within permitted window
    - Week/month calendar views; ad hoc task merge at appropriate urgency level
    - Workload threshold alert with prioritisation reason display
    - _Requirements: 24.1, 24.2, 24.3, 24.4, 24.5, 24.6, 24.7_

  - [x]* 9.6 Write integration tests for HBNC/HBYC/ANC program flows
    - Test: delivery → HBNC schedule generated with correct visit dates
    - Test: LBW delivery → high-risk pathway enrolled, extra visits present in schedule
    - Test: ANC high-risk criteria fires correctly for each threshold value
    - Test: missed HBNC visit → overdue status set, rescheduled within window
    - Test: program completion → `IncentiveEvent` written with correct `activityCode`
    - _Requirements: 12.1, 14.3, 54.1_

- [x] 10. Immunization, growth/nutrition, NCD/CBAC, and TB support
  - [x] 10.1 Implement national immunization schedule and dose recording
    - Create `lib/features/clinical_programs/immunization/`: generate schedule from DOB (BCG/OPV0/OPV1-3/Penta1-3/IPV/fIPV/MR1-2/JE/VitA1-9/DPT booster/OPV booster); add to `VisitSchedule`
    - Dose recording: vaccine name/date/site/batch number (optional); update `members` immunization-card view
    - Defaulter list with catch-up schedule display
    - VHSND session: generate due-beneficiary list per service; record session attendance + services given → update individual beneficiary records
    - AEFI capture: symptoms/timing/severity; urgent AEFI → RED flag; sync alert to ANM/MO
    - U-WIN reconciliation stub in `workers/uwin_reconcile.py` (hook for Task 12)
    - TT/Td schedule added to ANC due list
    - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6, 16.7_

  - [x] 10.2 Implement WHO growth standards and malnutrition classification
    - Embed WHO child growth standard lookup tables in SQLite: WAZ (weight-for-age Z-score), HAZ (height-for-age), WFHZ (weight-for-height), MUAC classification tables for sex × age
    - Classify nutritional status offline: normal/MAM/SAM/stunting/underweight; plot on growth chart widget
    - SAM / bilateral oedema / appetite failure → RED + NRC referral
    - MAM → YELLOW + Anganwadi linkage + closer follow-up schedule
    - IFA/VitA/deworming due dates per national schedule; record administration with dose+date
    - Hb anaemia classification using WHO/national Hb thresholds per age/sex group
    - Malnutrition programme follow-up with exit criteria tracking (cured/defaulted/died/non-responder)
    - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5, 17.6_

  - [x] 10.3 Implement NCD/CBAC screening
    - Create `lib/features/clinical_programs/ncd/`: CBAC questionnaire for ≥30 years, offline score computation using official CBAC scoring rules, threshold breach → facility confirmation prompt
    - BP/glucose classification per national NCD guidelines → YELLOW/RED flag
    - Oral/breast/cervical cancer symptom flags → referral tracking + follow-up task
    - Hypertension/diabetes register: adherence check visits + medication-refill reminders + repeat measurement recording over time
    - Overdue NCD follow-up → tracing task
    - NCD app export format (CSV with fixed column headers)
    - Lifestyle counselling: short audio + pictorial messages for tobacco/alcohol/diet/salt/activity
    - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5, 19.6, 19.7_

  - [x] 10.4 Implement TB support and privacy protections
    - Create `lib/features/clinical_programs/tb/`: presumptive TB flagging (cough ≥2 weeks + fever/weight loss/night sweats/other listed symptoms)
    - Sputum sample record: sample ID/collection date/site/transport status/result receipt
    - TB treatment registration: treatment supporter name+contact, dose observation visits per regimen
    - Consecutive-miss alert: configurable threshold → ASHA alert + backend notify designated TB programme staff
    - Household contact list for symptom screening + preventive therapy prompt
    - Ni-kshay sync hook in `workers/nikshay_sync.py` (polling every 4 hours)
    - Nutrition/social support linkage with outcome recording
    - TB privacy: replace TB labels with neutral terms in shared/supervisor-facing views; stricter role-based visibility
    - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5, 20.6, 20.7, 20.8_

  - [x]* 10.5 Write property tests for WHO Z-score monotonicity (Property 8)
    - **Property 8: WHO Z-Score Monotonicity**
    - For arbitrary (height, age_days, sex) within plausible physiological bounds, assert increasing weight never decreases weight-for-age Z-score
    - **Validates: Requirements 17.1**

  - [x]* 10.6 Write unit tests for immunization schedule generation, CBAC scoring, and TB privacy
    - Test: BCG/OPV/Penta schedule generated correctly from DOB
    - Test: CBAC score computation matches reference table for representative inputs
    - Test: TB label hidden in shared-device view; visible in ASHA private view
    - Test: consecutive missed doses count correctly triggers alert
    - _Requirements: 16.1, 19.1, 20.4, 20.8_

- [x] 11. Checkpoint — verify clinical programs and triage integration
  - Run all clinical program integration tests. Verify a complete flow: register household → ANC registration → high-risk flag fires → referral generated → HBNC scheduled on delivery → immunization schedule correct → NCD screening scores correctly. Ensure all tests pass, ask the user if questions arise.

- [x] 12. Due list, reminders, VHSND, BLE devices, and measurement tools
  - [x] 12.1 Implement reminders and beneficiary communication
    - Add `flutter_local_notifications` (no network required); schedule notification when `VisitSchedule.due_date` is reached
    - Backend: opt-in SMS/IVR to beneficiary phone using configured SMS gateway; messages in beneficiary's language with no sensitive health details; delivery receipt recording
    - Template messages in local language; one-tap call/message to ANM/AF/MO from beneficiary record, referral screen, and help screen
    - Quiet-hours config; batch daily notification summary for non-urgent alerts
    - _Requirements: 26.1, 26.2, 26.3, 26.4, 26.5, 26.6_

  - [x] 12.2 Implement route planning and offline maps
    - Create `lib/features/due_list/domain/route_planner.dart`: nearest-neighbour hamlet ordering using household lat/lon (opt-in GPS only; no continuous background tracking)
    - Offline OpenStreetMap tile display (district-level base tiles bundled ~8 MB; block tiles as OTA download) using `flutter_map`
    - Seasonal/remote hamlet flag with reason; adjust scheduling to reflect unavailability
    - Coverage heatmap aggregate view for supervisors (requires ASHA consent)
    - _Requirements: 25.1, 25.2, 25.3, 25.4, 25.5_

  - [x] 12.3 Implement VHSND session planning and health education library
    - VHSND: session beneficiary list per service (immunization/ANC/CBAC/FP) + mobilisation checklist + session summary form; attendance + services recording → update individual beneficiary timelines; VHSNC meeting log
    - Offline health education library: audio clips/illustrated messages/video content in SQLite-backed asset index, searchable by health topic; campaign checklists for pulse polio/MDA/IFA week/TB
    - _Requirements: 27.1, 27.2, 27.3, 27.4, 27.5, 27.6_

  - [x] 12.4 Implement BLE device integration
    - Create `lib/features/devices/ble_service.dart` using `flutter_reactive_ble`; load device profiles from `device_profiles` table (service UUID/characteristic UUID/unit/min-max range); connect only when measurement screen is active, disconnect on navigation away (no background scanning)
    - Supported device types: BP monitors/pulse oximeters/thermometers/glucometers/haemoglobinometers/weighing scales
    - Out-of-range reading → prompt remeasure before save
    - Tag measurement source: `BLE:<device_id>` or `MANUAL`; associate with active patient + authenticated user
    - Manual fallback always available without workflow loss
    - Add new device type via `device_profiles` config insert (no code change required)
    - _Requirements: 28.1, 28.2, 28.3, 28.4, 28.5, 28.6, 28.7_

  - [x] 12.5 Implement zero-hardware measurement aids
    - Breath counter: 60-second tap-to-count timer with audible cues; compute respiratory rate; apply age-appropriate fast-breathing threshold from embedded classification table
    - MUAC colour-coded reference guide: red < 11.5 cm, yellow 11.5–12.5 cm, green > 12.5 cm (WHO/UNICEF tape colour coding)
    - Timed procedure timers with expiry vibration + audio notification
    - Experimental camera-based measurements: label prominently as "experimental"; require clinical validation and CDSCO approval annotation; not usable as sole basis for reducing severity from RED/YELLOW
    - Clinical calculators (offline): EDD from LMP, gestational age, ASHA-scope drug doses (ORS/zinc/iron/paracetamol), BMI, WHO growth percentiles
    - _Requirements: 29.1, 29.2, 29.3, 29.4, 29.5_

  - [x] 12.6 Implement stock and equipment management
    - Create `lib/features/devices/stock_service.dart`: kit registry with serial numbers + issue dates; dispensing log with `quantity_delta` write to `stock_transactions` table; run-out estimate from current stock ÷ average daily consumption
    - Restock request works offline (write to `sync_queue`); sync to AF/backend on next connection
    - Minimum threshold alert + local notification
    - Device fault report form with optional photo attachment; calibration/replacement due list on ANM workspace
    - Stock-out date + item recorded; surface in PHC/district supply-chain dashboards via backend
    - _Requirements: 30.1, 30.2, 30.3, 30.4, 30.5, 30.6_

  - [x]* 12.7 Write unit tests for BLE integration, breath counter, and stock management
    - Test: out-of-range BLE reading triggers remeasure prompt (not auto-saved)
    - Test: source tag set to BLE device ID when from device, MANUAL when typed
    - Test: breath count of 62 taps in 60 s for INFANT_0_2M triggers RED flag
    - Test: stock below threshold triggers restock notification
    - Test: stock dispensing correctly decrements quantity and calculates run-out date
    - _Requirements: 28.3, 28.4, 29.1, 30.3_

- [x] 13. Paper outputs, government integrations, and incentive engine
  - [x] 13.1 Implement PDF register pages and paper-compatible outputs
    - Extend `lib/core/pdf/pdf_generator.dart` with register-format templates: village survey, RCH, HBNC, HBYC, PNC, high-risk pregnancy, CBAC, TB, immunization
    - Monthly report generation from on-device/synced data for the requested period
    - OTA template update via server-delivered config (no APK release required)
    - Full-screen scrollable on-screen register view + share-to-messaging-apps action for printerless situations
    - Family-friendly cards: MCP card update, vaccination card, referral slip in selected language
    - _Requirements: 34.1, 34.2, 34.3, 34.4, 34.5_

  - [x] 13.2 Implement incentive catalogue and auto-event logging
    - Create `lib/features/incentives/domain/incentive_service.dart`: load state-specific incentive catalogue JSON from sync'd config (no hardcoded rates); check eligibility against catalogue conditions on every task completion; write `IncentiveEvent` with `idempotency_key = hash(activityCode + memberId + eventDate)`; deduplicate via `UNIQUE INDEX` on `idempotency_key`
    - Deferred eligibility: track pending conditions (e.g., full immunization confirmed at age 1); mark eligible only when condition satisfied
    - Ineligibility reason display in ASHA's language with audio
    - Backend `services/incentive_service.py`: effective-dated catalogue versioning; rate lookup uses catalogue version active at event date
    - Duplicate claim detection (same event claimed by two workers) → flag for ANM review
    - _Requirements: 53.1, 53.2, 53.3, 53.4, 54.1, 54.2, 54.3, 54.4, 54.5, 54.6_

  - [x] 13.3 Implement earnings dashboard
    - Create `lib/features/incentives/presentation/earnings_screen.dart`: current month totals by status (eligible/claimed/verified/approved/paid/rejected) with per-task breakdown; delay/rejection shows stage+reason+responsible person; payment date + bank reference reconciliation; earnings projection; printable PDF earnings statement; local language + audio summary; private (requires app unlock, hidden in recent-apps)
    - _Requirements: 55.1, 55.2, 55.3, 55.4, 55.5, 55.6_

  - [x] 13.4 Implement claim voucher generation and submission
    - Auto-generate claim voucher at period close: PDF + digital record; line items: activity code/member coded ID/service date/amount/evidence link
    - Route to ANM/AF for verification via backend queue; per-line approve/reject/correct with mandatory reason; sampling-based verification support
    - Rejected line → ASHA notified with reason + resubmit capability
    - Backend `services/incentive_service.py`: forward approved claim to ASHA Soft/PFMS API where available; otherwise generate state-format export CSV
    - Bank detail validation: IFSC format, account format, Aadhaar-seeding API check, flag mismatches before payment cycle runs
    - _Requirements: 56.1, 56.2, 56.3, 56.4, 56.5, 56.6, 56.7, 57.1_

  - [x] 13.5 Implement dispute resolution and payment tracking
    - Dispute workflow: ASHA selects disputed period/task, attaches event log evidence, submits; backend assigns owner, tracks SLA, escalates if unresolved within configurable threshold
    - Bank/PFMS rejection → surface rejection reason code in plain language + correction steps
    - Payment delay alert to Block/District Officer after configurable days (default 45) post-claim approval
    - Reconciliation report for auditors: event → incentive log → claim voucher → approval → payment with tamper-evident audit trail
    - _Requirements: 57.2, 57.3, 57.4, 57.5, 57.6_

  - [x] 13.6 Implement government system integrations
    - Backend `workers/uwin_reconcile.py`: daily CSV import from U-WIN; reconcile vaccination status with local records; create stubs for unmatched RCH IDs; conflict review for date mismatches
    - Backend `workers/nikshay_sync.py`: polling every 4 hours; import case ID/diagnosis/regimen/status/outcome; export presumptive TB flags and follow-up records on ANM approval
    - Backend `workers/hmis_export.py`: compute 45+ monthly HMIS indicators from event data on 1st of month; present to ANM for review; export as state-specific Excel template
    - ABDM/ABHA: `workers/abdm_sync.py` generates FHIR R4 bundles (fhir_r4 library) for WellnessRecord/ImmunizationRecord/OPConsultation/DiagnosticReport; validates consent artifact before sharing; logs all outbound sharing to `outbound_sharing_log`
    - State-level field mapping config files (`nikshay_mapping.json`, `hmis_mapping.json`, etc.); no hardcoded field names
    - Integration call failures → log to incident table, surface rejection reason to ANM/ASHA; never block primary sync
    - _Requirements: 35.1, 35.2, 35.3, 35.4, 35.5, 35.6, 35.7, 36.1, 36.2, 36.3_

  - [x]* 13.7 Write property tests for incentive idempotence and historical rate invariant (Properties 10, 11, 12)
    - **Property 10: Incentive Event Deduplication**
    - Recording same eligible event N times must produce exactly one `IncentiveEvent` record
    - **Property 11: Incentive Historical Rate Invariant**
    - Any claim submitted before a catalogue effective-date change must compute rate using the catalogue version active at event completion date
    - **Property 12: Claim Line-Item Round-Trip**
    - `parse(generate_pdf(claim)) == claim` — all line items survive PDF round-trip with no truncation or precision loss
    - **Validates: Requirements 53.2, 54.1, 56.1**

  - [x]* 13.8 Write property test for FHIR resource round-trip (Property 17)
    - **Property 17: FHIR Resource Serialisation Round-Trip**
    - For arbitrary valid FHIR R4 resources generated by the backend, assert `parse(serialise(resource)) == resource` using `fhir_r4` Python library
    - **Validates: Requirements 36.2, 52.6**

- [x] 14. React web dashboards — AF supervision, PHC, analytics, and admin console
  - [x] 14.1 Scaffold React web application
    - Create `web-dashboard/` with Vite + React 18 + TypeScript + TailwindCSS
    - Add dependencies: `react-query`, `react-router-dom v6`, `recharts`, `workbox`, `axios`, `i18next`
    - Configure React Query client (`queryClient.ts`) and typed API client wrappers in `src/shared/api/`
    - Set up role-based route protection for AF, ANM, PHC, District, and Admin layouts
    - _Requirements: 39.1, 40.1, 41.1, 42.1, 43.1_

  - [x] 14.2 Implement ASHA Facilitator supervision dashboard
    - Create `src/features/af-supervision/`: per-ASHA cards showing coverage%/overdue count/pending referrals/RED flags with resolution status/data quality indicators/learning progress (updated at last sync)
    - Digital supervision checklists (observing visit/checking records/reviewing equipment+stock) — offline-capable via service worker + IndexedDB
    - Mentoring pattern detection with supportive framing ("may benefit from refresher on X")
    - Workload heatmap; feedback/recognition: send text/voice note/badge to ASHA device
    - Issue resolution logging with follow-up check scheduling
    - _Requirements: 39.1, 39.2, 39.3, 39.4, 39.5, 39.6_

  - [x] 14.3 Implement ANM/CHO workspace
    - Create `src/features/anm-workspace/`: new registration/ANC/PNC updates/immunization/referral data with validation error highlighting
    - VHSND/sub-centre clinic session entry: session beneficiary list, services recording → update individual timelines
    - Incentive verification queue: review underlying event records as evidence per line item
    - RED-flag and high-risk case alerts with full referral note and ASHA contact
    - Government portal export: guided data-entry assistant pre-filling from existing data (for ANMOL/HMIS/POSHAN Tracker)
    - Offline-capable tablet experience (Workbox service worker, IndexedDB for drafts and pending verifications)
    - _Requirements: 40.1, 40.2, 40.3, 40.4, 40.5, 40.6_

  - [x] 14.4 Implement PHC and facility dashboard
    - Create `src/features/phc-dashboard/`: live referral queue sorted by severity (RED first), polled every 30 s (`refetchInterval: 30_000`); full referral note + patient history + ASHA contact per card
  - [-] 14.7 Implement national map source registry and server-backed layers
    - Register HFR/NHRR, HealthGIS, HMIS, OSM, LGD, Bhuvan, Geofabrik, population, blood-bank, pharmacy, and environmental sources.
    - Render verified `FacilityDirectory` records from `/api/v1/facilities` with source-aware marker categories; complete source ingestion remains required before a source can produce points.
    - Outcome recording (arrived/treated/admitted/discharged/did not reach) → backend pushes notification to ASHA
    - Active lists: high-risk pregnancies/sick newborns/SAM/NCD defaulters/TB patients (filterable by sub-centre and ASHA)
    - Facility planning view: deliveries expected in next 4 weeks/immunization session demand/commodity stock levels/outstanding referral outcomes
    - Doctor-to-ASHA instruction (short text or voice note)
    - Lightweight slow-connection mode: cached data rendered first, progressive loading of analytics components
    - _Requirements: 41.1, 41.2, 41.3, 41.4, 41.5, 41.6_

  - [x] 14.5 Implement district/state analytics and admin console
    - Create `src/features/analytics/`: near-real-time coverage indicators; choropleth maps (Recharts + OpenStreetMap base); outbreak/cluster alerts; supply forecasting by commodity; data quality heatmap by area; de-identified CSV exports; benchmarking vs targets and prior period
    - Re-identification guard: cells with count < configurable minimum show aggregated figures or are suppressed
    - Create `src/features/admin/`: bulk user onboarding (CSV upload to `POST /admin/users/bulk`), role+area assignment, org hierarchy propagation, configuration versioning + staged rollout + rollback UI, deployment monitoring (app versions/sync times/failure rates/storage/device health), state setup checklist
    - _Requirements: 42.1, 42.2, 42.3, 42.4, 42.5, 42.6, 42.7, 43.1, 43.2, 43.3, 43.4, 43.5, 43.6_

  - [x]* 14.6 Write integration tests for React dashboard API wiring and offline ANM workspace
    - Test: referral queue polls backend and renders RED referrals first
    - Test: recording referral outcome triggers ASHA notification on backend
    - Test: ANM workspace loads from IndexedDB when offline
    - Test: admin bulk user CSV upload creates correct role assignments
    - _Requirements: 41.1, 41.2, 40.6_

- [x] 15. Training, AI safety, privacy, compliance, and remaining programs
  - [x] 15.1 Implement micro-learning module
    - Create `lib/features/learning/`: offline content library (audio/video/illustrated, 12 languages) with SQLite-backed asset index; 2–5 min lessons + quiz (≤5 questions); progress + scores in `learning_progress` table
    - Spaced-repetition quiz scheduler; max daily lesson count for mandatory courses (prevent single-session click-through)
    - Gap-triggered lesson suggestions: detect repeated danger-sign step skips / high override rate / missed IFA records → suggest micro-lesson with supportive framing, not warning
    - RED triage flag → offer optional 2-min danger-sign refresher link
    - Offline scenario-based practice (simulated clinical cases, no real beneficiary records)
    - Completion record with timestamp + quiz scores synced to AF + training system
    - Trainer content publishing: backend supports versioning + language variants + role-based assignment; app downloads in background + notifies ASHA
    - Searchable offline reference-card library (job aids from official ASHA training material)
    - Soft-skills modules: community communication/health counselling/negotiation/financial literacy/stress management/self-efficacy
    - _Requirements: 37.1, 37.2, 37.3, 37.4, 37.5, 37.6, 37.7, 37.8, 37.9, 37.10_

  - [x] 15.2 Implement teleconsultation and peer support
    - One-tap call actions to ANM/CHO/MO and national/state helplines (104/108/102) via `tel:` URI — works over basic voice with no data
    - Async case sharing: pre-formatted message with minimum necessary clinical details + consent check; e-Sanjeevani deeplink
    - Opt-in moderated peer group with voice-note + text Q&A; shares only minimum necessary details with explicit consent
    - _Requirements: 38.1, 38.2, 38.3, 38.4_

  - [x] 15.3 Implement remaining clinical programs
    - Family planning (Req 18): eligible couple list/method-comparison flow (pictorial+audio)/contraceptive dispensing+stock decrement/side-effect handling/postpartum counselling prompt/IUCD+injectable incentive event/extra privacy (stricter role visibility, omit from household-shared views)
    - Communicable disease and malaria (Req 21): malaria RDT recording (endemic area mapping from config) + treatment routing; outbreak alert logic — threshold cases of same syndrome in same hamlet within configurable time window → alert on sync to ANM/AF/MO; notifiable disease surveillance data capture + IDSP routing; supervisor-pushed response checklists presented at top of home screen; animal/snake bite/poisoning first-aid protocol + immediate referral prompt
    - Other programs (Req 22): adolescent register + menstrual hygiene counselling + WIFS tablet distribution with stock decrement; elderly/palliative home-care follow-up list with configurable visit interval; mental health screening aid (scope-appropriate validated tool) + helpline numbers (iCall/Vandrevala/104/NIMHANS); disability registration + government scheme linkage; configurable new programme module loaded via OTA config (form + schedule + rules, no APK release); community activity logs (household survey/awareness session/sanitation drive/VHSNC meeting) with date/participant count/notes rolling up to AF dashboard
    - Vital events (Req 23): birth/death civil registration data capture (CRS format); maternal/infant/child death review form → backend alert to AF/ANM/MO; stillbirth/abortion minimal mandatory fields + restricted visibility + neutral language; household registry update (membership counts + statuses) + cancellation of pending tasks for deceased/migrated persons
    - _Requirements: 18.1–18.7, 21.1–21.6, 22.1–22.6, 23.1–23.4_

  - [x] 15.4 Implement AI safety, worker privacy, and DPDP compliance
    - AI safety: all CDSS suggestions labelled "decision support" + ASHA confirmation required before recording; lower-severity system suggestion triggers reconsideration prompt ("Does the child look lethargic?"); backend tracks override rates by rule/language/area/cohort with clinical team threshold alerts; safety incident workflow with structured fields; poor-performing component disable capability; ASHA feedback captured on every override
    - DPDP compliance: purpose-limitation metadata on every record write; SAR/correction/erasure tracked request workflow; breach incident log; every data access logged with user+purpose; anomalous access alert
    - Worker privacy: plain-language audio install notice (what is collected/who sees it/how used); location opt-in per feature; ASHA sees same performance data as supervisor; grievance submission channel with owner + status tracking; policy-gated analytics (explicit leadership sign-off + worker notification before appraisal use)
    - Stigmatised condition privacy (TB/HIV/MH/FP): role-based visibility enforcement + neutral labels in shared/supervisor views
    - Rooted device detection on launch → restrict sensitive data access + show support contact
    - Crash diagnostics: local stack trace (no PHI) → transmit on connectivity; "report a problem" action with PII-stripped screenshot
    - _Requirements: 44.1–44.9, 45.1–45.6, 46.1–46.8_

  - [x] 15.5 Implement end-to-end integration wiring
    - Verify the complete flow functions as a single path: household registration → ANC registration → triage → RED referral → referral outcome → HBNC scheduling → immunization → NCD screening → incentive event → claim voucher → payment tracking
    - Wire due list tasks auto-generated at every step; confirm all `IncentiveEvent` idempotency keys resolve correctly
    - Confirm all 15 programs emit events that surface correctly in AF/PHC/District dashboards after sync
    - _Requirements: All parts 1–11_

  - [x] 15.6 Implement QMS scaffold
    - Create `docs/qms/`: intended-use statement; CDSCO SaMD classification analysis (lay-user community health worker triage); requirements-to-test traceability matrix (`req_id → test_file → test_name`); risk management file template (hazard / harm / probability / severity / risk control / residual risk per IEC 62304 / ISO 14971); change-control procedure; validation evidence log template; complaint handling and vigilance-reporting procedure
    - _Requirements: 47.1, 47.2, 47.4, 47.5, 47.6_

  - [x] 15.7 Performance tuning and production readiness
    - Profile Flutter app on 2 GB RAM Android 9 reference device; confirm all screens render < 1 s and triage < 1 s
    - Run `EXPLAIN QUERY PLAN` assertions in CI for all benchmark queries; fail CI on full-table-scan regression
    - Verify base APK size < 50 MB in CI (fail build if exceeded)
    - Implement low-power mode: dark theme + reduced animation + deferred non-critical sync to Wi-Fi + disabled non-essential background tasks
    - Delta APK patch delivery; deferred download on slow connections with full functionality on current version
    - Reduced-feature mode for devices < Android 9 or < 1.5 GB RAM (tap-only, no voice model, simplified triage)
    - Docker Compose deployment: `docker-compose.yml` with FastAPI + PostgreSQL 16 + Redis + Celery worker + React build served via Nginx
    - GitHub Actions CI pipeline: lint → Flutter test (with `--no-sound-null-safety` if needed) → APK size check → pytest backend → build Docker images → deploy to staging
    - Backup and restore test procedure (automated quarterly restore test in CI)
    - _Requirements: 48.1–48.7, 50.1_

  - [x] 15.8 Accessibility audit and final compliance checks
    - Run automated WCAG AA contrast check on all screens using `flutter_accessibility_service` lint rules
    - Verify all interactive elements have ≥ 48 × 48 dp touch targets via lint check
    - Manual TalkBack screen-reader compatibility test on reference device (document results in QMS)
    - Verify Android `FLAG_SECURE` applied to earnings screen and all patient-data screens
    - Run `hypothesis` property test suite (all 18 properties) with `max_examples=500` for release validation
    - _Requirements: 49.1–49.5_

  - [x] 15.9 Write property tests for clinical record serialisation round-trip and audit hash-chain tamper detection (Properties 1, 14, 15)
    - **Property 1: Clinical Record Serialisation Round-Trip**
    - For arbitrary valid clinical records (Member, ClinicalEncounter, ConsentArtifact, IncentiveClaim), assert `deserialise(serialise(record)) == record` across all field types
    - **Property 14: Audit Hash-Chain Tamper Detection**
    - For any synced audit log chain, modifying any byte of any historical entry must cause chain-hash verification to fail
    - **Property 15: Event-Log Replay Consistency**
    - Replaying the ordered event log from the beginning must reproduce current field values of the record
    - **Validates: Requirements 1.2, 5.2, 33.2, 33.3**

  - [x] 15.10 Write property test for conflict merge confluence (Property 16)
    - **Property 16: Conflict Merge Confluence**
    - For any two independent offline edit sets A and B on the same base record, assert `merge(A, merge(B, base)) == merge(B, merge(A, base))` for all non-conflicting fields
    - **Validates: Requirements 32.2**

- [x] 16. Final checkpoint — full system validation
  - Run the complete property test suite (all 18 properties, 500 iterations each). Run all integration tests. Build the APK and verify size < 50 MB. Verify Docker Compose stack starts cleanly. Walk through the end-to-end flow (registration → triage → referral → incentive → claim) against a staging backend. Ensure all tests pass, ask the user if questions arise.

---

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP; all unmarked tasks are required.
- Each task references specific requirement IDs for traceability.
- Checkpoints (Tasks 3, 7, 11, 16) are integration validation milestones, not coding tasks.
- The QMS scaffold (Task 15.6) produces documentation artefacts, not runtime code, but is required for CDSCO regulatory compliance.
- Property tests use `package:glados` (Dart) and `hypothesis` (Python); both require at minimum 200 iterations per property; use 500 for release.
- All 18 correctness properties from the design document are covered by property test sub-tasks distributed close to the code that implements them.
- The `[VALIDATE]` items in requirements.md (HBNC visit schedule, CBAC scoring thresholds, ANC high-risk thresholds, endemic area mapping) must be resolved against official NHM/NHSRC documents before the corresponding sub-tasks are implemented; stubs are acceptable for earlier tasks.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "1.3"] },
    { "id": 2, "tasks": ["1.4", "1.5", "1.6"] },
    { "id": 3, "tasks": ["1.7", "2.1"] },
    { "id": 4, "tasks": ["1.8", "1.9", "2.2", "2.3"] },
    { "id": 5, "tasks": ["2.4", "2.5"] },
    { "id": 6, "tasks": ["2.6", "2.7", "2.8", "2.9"] },
    { "id": 7, "tasks": ["2.10", "2.11", "4.1"] },
    { "id": 8, "tasks": ["4.2", "4.3"] },
    { "id": 9, "tasks": ["4.4", "4.5"] },
    { "id": 10, "tasks": ["4.6", "5.1"] },
    { "id": 11, "tasks": ["4.7", "4.8", "5.2", "5.3"] },
    { "id": 12, "tasks": ["5.4", "5.5", "5.6"] },
    { "id": 13, "tasks": ["5.7", "5.8"] },
    { "id": 14, "tasks": ["5.9", "5.10", "6.1"] },
    { "id": 15, "tasks": ["6.2"] },
    { "id": 16, "tasks": ["6.3", "6.4"] },
    { "id": 17, "tasks": ["6.5", "6.6", "6.7"] },
    { "id": 18, "tasks": ["8.1", "8.2"] },
    { "id": 19, "tasks": ["8.3", "8.4", "8.5"] },
    { "id": 20, "tasks": ["8.6", "9.1", "9.2"] },
    { "id": 21, "tasks": ["9.3", "9.4"] },
    { "id": 22, "tasks": ["9.5"] },
    { "id": 23, "tasks": ["9.6", "10.1"] },
    { "id": 24, "tasks": ["10.2", "10.3", "10.4"] },
    { "id": 25, "tasks": ["10.5", "10.6", "12.1", "12.2"] },
    { "id": 26, "tasks": ["12.3", "12.4", "12.5"] },
    { "id": 27, "tasks": ["12.6"] },
    { "id": 28, "tasks": ["12.7", "13.1", "13.2"] },
    { "id": 29, "tasks": ["13.3", "13.4"] },
    { "id": 30, "tasks": ["13.5", "13.6", "14.1"] },
    { "id": 31, "tasks": ["13.7", "13.8", "14.2", "14.3"] },
    { "id": 32, "tasks": ["14.4", "14.5"] },
    { "id": 33, "tasks": ["14.6", "15.1", "15.2"] },
    { "id": 34, "tasks": ["15.3", "15.4"] },
    { "id": 35, "tasks": ["15.5"] },
    { "id": 36, "tasks": ["15.6", "15.7"] },
    { "id": 37, "tasks": ["15.8"] },
    { "id": 38, "tasks": ["15.9", "15.10"] }
  ]
}
```
