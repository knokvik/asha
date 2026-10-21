# ASHA Setu — Complete Project Context and Handoff

This document is the working context for the ASHA Setu project. It is intended to be given to a new engineer, product agent, reviewer, or coding assistant before making changes.

It describes the current repository, intended product, implemented behavior, clinical and data-safety boundaries, technical architecture, integrations, map strategy, tests, deployment, known gaps, and the correct development workflow.

## 1. Product identity

ASHA Setu is an offline-first health information and referral platform for Accredited Social Health Activists (ASHAs), ASHA facilitators, ANMs/CHOs, PHC staff, doctors, district supervisors, and administrators.

The core product promise is:

> An ASHA can register households, assess people, receive safe clinical decision support, find the correct referral capacity, create a paper-compatible referral, and continue working without mobile internet. When connectivity returns—or when two workers meet—the data synchronises with the server and the PHC dashboard.

This is not a generic hospital map or a diagnosis app. It is a field workflow system whose main loop is:

```text
Household / beneficiary
        ↓
Consent + visit + measurements + symptoms
        ↓
Offline triage and programme pathway
        ↓
Capability-aware referral destination
        ↓
Ticket / referral / SMS / QR / PDF / attachment
        ↓
Offline queue, tower sync, or peer-to-peer sync
        ↓
PHC dashboard acknowledgement, consultation, outcome
        ↓
Notification, follow-up task, history, audit, learning signal
```

The product is currently designed for light mode. Dark mode is not a current product requirement.

## 2. Repository map

```text
.
├── backend/                         FastAPI + SQLAlchemy + Alembic backend
├── mobile/                          Flutter Android/iOS field application
│   ├── lib/app/                     Theme, router, app shell
│   ├── lib/core/                    Database, security, sync, triage, voice
│   ├── lib/features/                Feature-first screens and domain services
│   └── packages/                    Local Dart packages, triage and geo intelligence
├── web-dashboard/                   React + TypeScript PHC/supervisor dashboard
├── .kiro/specs/asha-digital-platform/
│   ├── requirements.md              Product requirements and acceptance criteria
│   ├── design.md                    Architecture, schema, API and safety design
│   └── tasks.md                     Implementation plan and progress tracking
├── backend/config/                  Runtime and government-source configuration
├── backend/db/migrations/           Alembic migrations
├── render.yaml                      Render backend deployment definition
├── docker-compose.yml                Local infrastructure definition
├── requirements.md                   Additional project/problem requirements
├── AGENTS.md                        Repository rules for coding agents
└── PROJECT_CONTEXT.md               This handoff document
```

Important: `.env`, `.env.production`, database passwords, Supabase keys, JWT secrets, and tokens are local deployment secrets. Never copy them into this document, source control, logs, screenshots, or prompts.

## 3. Technology stack

### Mobile

- Flutter 3.x and Dart 3.x.
- Feature-first architecture under `mobile/lib/features`.
- Riverpod for state and dependency injection.
- `go_router` for navigation and role-aware routes.
- Drift ORM over SQLite.
- SQLCipher for encrypted local patient data.
- `flutter_secure_storage` for PIN hashes, salts, tokens, and device secrets.
- `flutter_map` and `latlong2` for map rendering.
- Offline raster map packs / MBTiles-compatible providers and cached GeoJSON/context packs.
- `flutter_reactive_ble` for measurement devices.
- `nearby_connections` for Android worker-to-worker exchange.
- Vosk/sherpa/ONNX-related voice stack and `flutter_tts` for offline voice input/output.
- `image_picker`, `record`, `archive`, `audioplayers` for evidence attachments and compressed voice.

### Backend

- FastAPI, Python 3.12-compatible code.
- Async SQLAlchemy.
- PostgreSQL in production, Supabase PostgreSQL through the Render-compatible Session Pooler.
- Alembic migrations.
- JWT authentication and tenant context derived from claims.
- Optional Redis/Celery integration for background work.
- Gzip-compressed sync payloads and idempotent event processing.

### Web dashboard

- React, TypeScript, Vite, TailwindCSS.
- React Router.
- TanStack React Query.
- Axios API client.
- Leaflet and marker clustering for maps.
- Recharts for analytics.
- Vitest and Testing Library.

## 4. User roles and surfaces

### ASHA mobile worker

- Login with ASHA ID and PIN.
- CAPTCHA/verification is an online authentication concern; offline continuation uses device-bound offline credentials/PIN.
- Home dashboard with due work, sync state, quick actions, map summary, shared area signals, notifications, and profile.
- Household and beneficiary registry.
- Search assistant for people, medicines, guidance, programmes, danger signs, and safety warnings.
- Unified adaptive triage for young infant, child, adolescent, adult/older adult, and pregnancy pathways.
- Triage history and referral history.
- Referral slip with facility selection, capability rationale, PDF, image, SMS, QR, attachments, and transport actions.
- Offline map with facilities, disease radar, households, live location, route context, source-aware categories, and service filters.
- Due list, calendar, tasks, reminders, VHSND, learning, interpreter, inventory, incentives, reports, settings, and peer sync.

### ANM / CHO / facilitator

- Area-level supervision.
- Follow-up and referral outcomes.
- Clinical programme workspaces.
- Checklists, recognition, instructions, and due tasks.

### PHC / doctor / facility staff

- Authenticated dashboard.
- Live referral/ticket queue.
- Priority ordering with RED first.
- Ticket acknowledgement, consultation, outcome recording, rerouting, and follow-up.
- Attachment access for compressed photos/audio.
- Facility and resource views.
- Stock, reports, analytics, and map layers.

### District/state/admin

- Coverage and disease radar.
- Facility/source registry.
- Configuration and rule versioning.
- Government integration reconciliation.
- Incentive catalogue, claims, payment tracking, disputes, and audit.

## 5. Mobile architecture

### App and routing

Primary entry points are defined in `mobile/lib/app/router.dart`. Routes include authentication, home, household, visit, triage, referral, map, programmes, learning, incentives, sync, profile/settings, supervision, and reports.

The app shell uses a common title bar and fixed bottom navigation. The product UI is light-mode-first; avoid introducing dark surfaces or dark-only map chrome unless explicitly requested.

### Core services

- `core/database`: Drift schema, encrypted database opening, local migrations, generated database code.
- `core/security`: PIN/device security, remote wipe, screen privacy, secure storage, certificate pinning.
- `core/sync`: sync engine, queue, worker, conflict resolution, SMS fallback, nearby peer transport, peer packets, audit-chain support.
- `core/triage`: pure deterministic rule evaluator, rule versions, models, findings, age bands, overrides.
- `core/voice`: voice input and ASR feedback storage.
- `core/vitals`: manual and BLE vital measurement support.
- `core/pdf`: referral and paper-compatible PDF generation.
- `core/l10n`: ARB localisation files for Indian languages.

### Local database

Important Drift tables include:

- users
- households
- members
- consent_records
- clinical_encounters
- clinical_observations
- triage_results
- referral_records
- visit_schedules
- incentive_events
- incentive_claims
- sync_queue
- rule_versions
- audit_log
- drafts
- stock_items
- stock_transactions
- facility_directory
- learning_progress
- device_profiles

The local database must remain encrypted at rest. The SQLCipher key is derived from the device/PIN security flow and held through secure storage; do not silently open production patient storage as plaintext SQLite.

## 6. Authentication and device safety

The intended flow is:

```text
First online login: ASHA ID + PIN/verification + CAPTCHA
        ↓
Server returns short-lived access token, refresh token, device-bound offline credential
        ↓
Next opens: local PIN verification works offline
        ↓
When connected: refresh token, sync user profile/tasks/assignments/facility data
```

Security constraints:

- Store only hashes/salts/tokens in hardware-backed secure storage.
- Use device-bound offline credentials with expiry.
- Enforce screen privacy/FLAG_SECURE for sensitive screens.
- Do not expose patient data in peer packets.
- Do not log PINs, tokens, database URLs, Supabase keys, or raw audio/transcripts by default.
- CAPTCHA is not a substitute for offline authentication; it is a server verification step.

Backend auth routes:

- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/revoke`
- `GET /api/v1/auth/me`

## 7. Offline-first and synchronisation design

The local app remains usable without network. Every write that must reach the server is represented in the local queue/event log and is retried idempotently.

### Normal tower sync

```text
Local write → encrypted Drift record + sync queue event
        ↓
Connectivity available → gzip push to /sync/push
        ↓
Backend validates tenant + batch id + record identity
        ↓
Conflict-aware upsert and audit/event persistence
        ↓
Mobile pulls deltas from /sync/pull using table watermarks
        ↓
Local records, notifications, tasks, attachments, outcomes update
```

Important routes:

- `POST /api/v1/sync/push`
- `GET /api/v1/sync/pull`
- `GET /api/v1/sync/activity`
- `GET /api/v1/sync/hotspots`
- `POST /api/v1/sync/asr-feedback`
- `GET /api/v1/sync/triage-tickets/{ticket_id}/attachments/{attachment_index}`

### Conflict rules

- Client UUIDs are generated offline.
- Duplicate batches/events are idempotent.
- Different-field edits can merge.
- Same-field conflicts retain provenance for review; they are not silently discarded.
- Watermarks prevent downloading the same delta repeatedly.
- Hash-chained local/server audit entries detect tampering.

### Peer-to-peer ASHA exchange

Implemented in:

- `mobile/lib/core/sync/peer_sync_service.dart`
- `mobile/lib/core/sync/nearby_peer_transport.dart`
- `mobile/lib/features/sync/presentation/peer_sync_screen.dart`

Android Nearby Connections supports advertise, discover, connect, send, and receive. QR/paste remains as fallback.

Peer packets contain only aggregate, de-identified area context:

- block and time window
- disease/module counts
- hotspot summaries
- area notifications
- packet ID and SHA-256 integrity hash

They explicitly exclude patient names, member IDs, ticket IDs, notes, images, and audio.

Imported context is merged into the offline triage/map cache. The dashboard shows received shared signals, and adaptive triage can use the cached area context.

### ASR feedback loop

Low-confidence voice confirmations/rejections create a local feedback record. Raw transcript retention is opt-in; default storage is hash-only plus canonical value, confidence, language, field type, and acceptance state. On sync, records go to `/api/v1/sync/asr-feedback` and are persisted for future evaluation/retraining.

## 8. Clinical triage system

The clinical engine is decision support, not autonomous diagnosis or prescribing. ASHA/clinical judgment remains final.

### Engine behavior

`mobile/lib/core/triage/triage_engine.dart` is a pure Dart evaluator:

- deterministic for identical inputs/rules;
- evaluates all applicable rules to collect findings;
- uses RED > YELLOW > GREEN severity;
- escalates when required information is missing;
- malformed/out-of-range vitals produce explicit errors and conservative escalation;
- ML may raise severity but never lower the rule result;
- stores rule version, engine version, model version, findings, missing fields, and overrides.

### Age and pathways

The unified flow resolves age into:

- young infant 0–2 months;
- child 2 months–5 years;
- adolescent;
- adult/older adult;
- pregnant woman.

The flow can incorporate danger signs, cough/breathing, diarrhoea, fever, feeding, malnutrition, pregnancy, NCD/CBAC, TB, communicable disease, and disease-radar context.

### Vitals and measurements

Manual fallback is required even when BLE hardware is available. Supported/expected measurements include temperature, respiratory rate, pulse, BP, SpO₂, weight, MUAC, haemoglobin, and glucose where applicable. Out-of-range values must never silently produce a green result.

### Triage audit and model governance

- Rules-only fallback operates when a TFLite/model asset fails.
- Every result records engine/model versions.
- Calibration report is maintained under `mobile/packages/triage/ml/REPORT.md`.
- Clinician-confirmed outcomes can flow to future, manually approved model versions.
- Clinical rule changes require versioning, source citation, approval, tests, hash verification, and rollback support.

## 9. Capability-aware referral routing

The referral system has two layers:

1. Generic facility matching (`FacilityMatcher`) for ordinary nearest qualifying care.
2. Capability-aware routing (`OfflineReferralRouter`) for scenarios where the nearest facility may be the wrong destination.

Implemented capability tags include:

- `blood_bank`
- `delivery_room`
- `nrc`
- `antivenom`
- `ab_hwc`
- `cho`
- `ncd_clinic`
- `pmjay`
- `janaushadhi`
- `vhsnd`
- `eye_bank`
- `ambulance_108`
- `ambulance_102`
- `emergency_112`
- `route_network_v1`
- `route_ferry_crossing`
- `route_ferry_safe`

Routing rules:

| Scenario | Required capacity | Emergency action |
|---|---|---|
| Obstetric bleeding | Blood bank + delivery room | Call 102/108 |
| SAM / MUAC <115 mm | NRC | Call 108 when urgent |
| Snakebite | Antivenom + blood | Call 108; avoid known ferry crossings |
| High BP without danger sign | AB-HWC + CHO/NCD evidence | Routine confirmation pathway |
| Routine | Nearest qualifying primary care | Show Jan Aushadhi companion where verified |

Important safety rule: a specialised scenario does not fall back to an unverified generic PHC. If the offline pack lacks verified capacity, the app shows a warning and emergency verification instruction.

The referral UI now displays the routing rationale, candidate facilities, capabilities, and warnings.

## 10. Map system

The map is a referral and field-work system, not just a basemap.

### Existing map layers

- OpenStreetMap base tiles and offline state/district packs.
- Facility directory markers.
- Health facility categories.
- Blood banks.
- Households and due visits.
- Disease radar/hotspot circles.
- Referrals and risk signals.
- Live worker location with accuracy marker.
- Route/road context where available.
- Satellite view where supported.

### New source-aware categories

Mobile filters/markers now include:

- PHC
- CHC
- blood bank
- NRC
- antivenom
- AB-HWC
- DEIC
- PM-JAY
- existing hospitals, sub-centres, pharmacies, Anganwadi, labs, etc.

The parser preserves capability lists from server map records so markers can be filtered by actual capability rather than only facility type.

### Source registry

`backend/config/india_map_source_catalog.json` is the source-of-truth catalog for map ingestion metadata. It records title, coverage, URL, access method, fields, normalized kind, capability tags, offline strategy, and status.

Registered source families include:

- ABDM Health Facility Registry.
- NHRR.
- NIC HealthGIS/data.gov.in.
- HMIS identifiers and indicators.
- OSM/Overpass health and community POIs.
- DataMeet GIS.
- state WCD/ICDS Anganwadi directories.
- Jan Aushadhi/PMBJP.
- e-RaktKosh blood banks.
- NHM NRC directories.
- RBSK DEIC.
- NHM 108/102 ambulance data.
- ERSS 112.
- NOTTO/state eye banks.
- NHA PM-JAY hospitals.
- VHSND block plans.
- LGD boundaries.
- Bhuvan/NRSC.
- Survey of India where licensed.
- Geofabrik India OSM extract.
- BBBike extracts.
- OpenMapTiles schema/styles.
- Census 2011 population.
- NFHS-5 district priors.
- Bhuvan DEM.
- IMD rainfall.

The API `GET /api/v1/map/sources` returns the catalog, capability-tag schema, and routing profiles.

### Critical source-ingestion truth

The catalog is not the same as imported verified points. Some sources require official exports, state-level lists, authorization, licensing, or periodic refresh. The app must not infer blood, NRC, antivenom, PM-JAY, or delivery capability from facility name/type alone.

## 11. Government and external integrations

Backend integration routes are grouped under `/api/v1/integrations`:

- U-WIN reconciliation CSV/JSON.
- Ni-kshay import/export.
- HMIS indicator calculation, approval, and CSV export.
- ABDM/FHIR bundle generation.
- Integration incidents and resolution.

Other backend areas:

- rules: signed rule bundle metadata and downloads;
- referrals: create/list/detail/outcome;
- triage desk: ticket sync, packs, queue, acknowledge, consult, outcome, analytics;
- reminders: send, receipt, dispatch, history;
- stock: stockout, PHC dashboard, district dashboard;
- supervision: ASHA lists, checklists, recognition;
- incentives: catalogue, events, claims, verification, disputes, reports;
- facilities: verified facility directory with capability filters.

## 12. Web dashboard architecture and screens

Main web areas include:

- Login/authentication.
- Main dashboard.
- PHC dashboard and ticket page.
- Resources.
- India/PHC map and OSM map.
- Disease/radar map panels.
- ANM workspace.
- ASHA facilitator supervision.
- District analytics.
- Admin console.
- Global search.
- Live sync activity/toasts.

The web dashboard should be server-backed for operational values. Mock data is permitted only when explicitly enabled for development; production must set the API base URL and disable mocks.

Important web environment concepts:

- `VITE_API_BASE_URL` points to the backend API prefix.
- `VITE_USE_MOCKS=false` when using the real backend.
- The dashboard must not hardcode production users, alerts, counts, tickets, or map data.

## 13. Backend data and migrations

The SQLAlchemy model layer includes users, households, members, consent, encounters, observations, triage results, triage tickets, referrals, reminders, incentives, claims, audit logs, facility directory, notifications, hotspot context, ASR feedback, conflicts, and integration incidents.

Recent important migrations include:

- triage attachments;
- triage audit/version fields;
- hotspot/area notifications;
- ASR feedback storage.

Deployment must run:

```bash
alembic upgrade head
```

Do not seed fake alerts or demo production data. Development fixtures must remain clearly isolated from production.

## 14. Deployment and environment

### Backend deployment

Render runs the backend from `backend/` using `render.yaml`:

```text
pip install -r requirements.txt
sh entrypoint.sh
```

The entrypoint applies migrations and starts the real API. Production uses `DEBUG=false`.

For Supabase on Render, use the Supabase Session Pooler URI copied from Supabase’s Connect panel. Render is IPv4-only in the documented setup, so direct `db.<project>.supabase.co` connections may fail with network unreachable; the pooler host is the supported configuration in `backend/.env.example`.

Required production configuration conceptually includes:

- `DATABASE_URL` — secret, never commit.
- `DATABASE_SSL_REQUIRE=true`.
- `DATABASE_POOL_MODE=session`.
- `SECRET_KEY` — generated long random secret.
- `ALLOWED_ORIGINS` — actual dashboard/mobile web origins.
- Redis/Celery values only when workers are enabled.

### Web deployment

Vite builds the dashboard. Vercel/render/nginx configuration is present. Configure the real API base URL and disable mocks.

### Mobile build

The release APK can be built from `mobile/`. A previous local build attempt was blocked by filesystem permissions on the Flutter SDK/Gradle caches, not by a diagnosed application compile error. Re-run on a machine where Flutter and Gradle caches are writable.

## 15. What has been solved in the project

The following areas have been implemented or substantially implemented:

- Light-mode mobile UI shell and common navigation.
- Real backend authentication and user profile flow.
- Supabase/PostgreSQL-compatible backend configuration.
- Offline PIN continuation and secure credential storage.
- Encrypted local Drift/SQLCipher database architecture.
- Offline household/beneficiary registry.
- Unified adaptive triage flow across life stages.
- Rules-only fallback, model audit versions, calibration/retraining scaffolding.
- Triage attachments with compression and explicit send-ticket behavior.
- Offline referral slips, PDF, QR, SMS fallback, and ticket history.
- PHC dashboard referral/ticket workflow and attachment retrieval.
- Sync queue, gzip payloads, delta pull, idempotence, watermarks, conflict records.
- Real-time activity panel/toasts on the web side.
- Area hotspot aggregation across multiple ASHAs.
- Privacy-preserving peer-to-peer area-context exchange.
- Offline adaptive triage context updated from server or peer signals.
- ASR feedback queue and server persistence.
- Offline maps, state packs, facility markers, disease radar, households, live location.
- Capability-aware facility routing and source-aware marker filters.
- National map source registry and source ingestion metadata.
- Core health programmes including ANC/PNC, HBNC, HBYC, immunization, nutrition, family planning, NCD, TB, communicable disease, VHSND, stock, learning, incentives, and reports.
- Government integration scaffolding for U-WIN, HMIS, Ni-kshay, ABDM/FHIR.

“Implemented” means code exists and is testable. It does not mean every government source has supplied a current, authorized, nationwide point dataset.

## 16. Important remaining work

### Highest priority

1. Import real, versioned state/district facility datasets into `facility_directory`.
2. Add source IDs, source record IDs, retrieved timestamps, license metadata, and verification dates to imported facility records.
3. Refresh blood stock and time-sensitive service availability; never display stale availability as live.
4. Connect DEIC, NRC, PM-JAY, VHSND, eye-bank, ambulance, and state Anganwadi feeds where authorized.
5. Apply all Alembic migrations in the deployed Supabase database.
6. Run the full Flutter test/build on a writable machine and launch the updated APK on a real Android phone.
7. Run web build/test against the deployed backend with mocks disabled.

### Clinical safety

- Validate exact thresholds and protocols against current state/NHM clinical guidance.
- Obtain clinical lead approval for rule changes.
- Validate triage prospectively/retrospectively against clinician-labelled cases.
- Keep emergency routing conservative when capability data is missing.
- Do not claim a route avoids a ferry unless a versioned offline road graph proves it.

### Operational

- Add background push/FCM only if required; in-app pull/sync currently works.
- Add state-level data refresh jobs and stale-data warnings.
- Set up monitoring for sync 4xx/5xx, 422 validation errors, database connectivity, queue age, and attachment failures.
- Document field onboarding, device migration, backup/restore, consent, and data deletion procedures.

## 17. Verification commands

From the repository root:

```bash
# Backend
cd backend
.venv/bin/python -m pytest -q
.venv/bin/ruff check .

# Mobile
cd ../mobile
flutter analyze
flutter test
flutter build apk --debug

# Web
cd ../web-dashboard
npm run lint
npm test
npm run build
```

If Flutter fails before analysis/test because the SDK cache is not writable, fix the environment permissions and rerun; do not weaken the code or tests.

## 18. Change discipline for future agents

1. Read `AGENTS.md` first.
2. Read the relevant requirements/design/task section before editing.
3. Inspect current implementation and tests.
4. Keep changes narrow and preserve existing user work.
5. Never print or commit secrets.
6. For clinical behavior, add boundary tests and source citations.
7. For sync behavior, test idempotence, tenant isolation, retry, and offline recovery.
8. For map data, distinguish source registration from verified imported records.
9. Run targeted verification before broad verification.
10. Update `.kiro/specs/asha-digital-platform/tasks.md` with progress and remaining work.
11. Do not commit or push unless the user explicitly asks.

## 19. One-paragraph context for a new app-building agent

Build and maintain ASHA Setu as an offline-first, privacy-preserving Indian public-health field platform. The Flutter mobile app is the source of truth while offline: it stores encrypted household, clinical, triage, referral, task, map, and audit data locally; it uses a deterministic, rules-first triage engine with human oversight; it creates capability-aware referrals and never silently routes high-risk cases to an unverified generic facility. The FastAPI/PostgreSQL backend is the synchronisation, multi-tenant, audit, notification, integration, and dashboard source of truth once connectivity returns. The React dashboard must read real server data when mocks are disabled and must show referrals, outcomes, attachments, maps, hotspots, resources, and sync activity. ASHA-to-ASHA peer exchange may share only de-identified aggregate area signals. Every map point and capability must have a source, timestamp, and verification status. Preserve offline operation, consent, encryption, auditability, clinical safety, and low-end-device usability in every change.
