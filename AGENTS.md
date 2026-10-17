# Project Instructions: ASHA Digital Platform

This document governs development workflows, architectural constraints, and coding standards for all AI agents working on the ASHA Digital Platform repository.

## 1. Specification Authority and Source of Truth

The primary project specifications are located in `.kiro/specs/asha-digital-platform/`:
- `requirements.md`: System requirements, functional/non-functional criteria, user journeys, and acceptance tests.
- `design.md`: Technical architecture, data models, security protocols, API contracts, and design properties.
- `tasks.md`: Execution plan, task dependencies, and progress tracking.

**Rules of Authority:**
1. Specifications take precedence over impromptu code changes. Understand the relevant requirement and design section before modifying code.
2. If code conflicts with specifications, identify the contradiction first. Never rewrite working code or silently alter specifications.
3. Traceability is mandatory: all features and bug fixes must map directly to documented requirements and tasks.

## 2. Inspect Before Modifying

1. Always inspect existing implementations, tests, and schemas before creating or changing files.
2. Identify reusable code, existing models, and shared utilities.
3. Preserve existing working implementations; do not refactor or overwrite without documented cause.

## 3. Controlled Development Loop

Follow this cycle for every implementation task:
1. **Task Selection:** Select the next unblocked task in `.kiro/specs/asha-digital-platform/tasks.md`.
2. **Planning:** Review parent requirements, design sections, affected files, and test strategies.
3. **Implementation:** Make cohesive, minimal, and backwards-compatible changes conforming to project patterns.
4. **Verification:** Run targeted unit tests, linters, analyzers, or builds. Never mark a task complete without verification evidence.
5. **Tracking Synchronization:** Update the task checkbox in `.kiro/specs/asha-digital-platform/tasks.md` (`[x]` for completed, `[-]` for partial).

## 4. Technology Stack & Coding Standards

- **Mobile Client:** Flutter 3.x (Dart 3.x) in `mobile/`.
  - Architecture: Feature-first structure (`app/`, `core/`, `features/`, `shared/`).
  - State Management: Riverpod with code generation.
  - Routing: GoRouter with role-based navigation guards.
  - Local Database: Drift ORM + SQLCipher AES-256 (`AppDatabase`). SQLite table schemas defined under `mobile/lib/core/database/tables/`.
  - Localisation: 12 Indian regional languages via ARB files under `mobile/lib/core/l10n/arb/`.
  - Audio/Voice: Vosk offline ASR + `flutter_tts` on-device.
- **Backend:** FastAPI (Python 3.12) in `backend/` (Task 2+).
  - ORM: Async SQLAlchemy + PostgreSQL 16 + Alembic migrations.
  - Multi-tenancy: Row-level isolation via JWT claims.
- **Web Dashboards:** React 18 + TypeScript + TailwindCSS (Task 13+).

## 5. Security and Data Privacy Standards

1. **Patient Data Encryption:** All local patient data must be encrypted at rest with SQLCipher AES-256. Keys derived using PBKDF2-HMAC-SHA256 (100,000 iterations).
2. **Credential Storage:** Store salts, PIN hashes, and tokens in hardware-backed secure storage via `flutter_secure_storage`.
3. **Screen Privacy:** Enforce `FLAG_SECURE` to prevent sensitive patient health information from leaking in recent-app snapshots.
4. **Secret Protection:** Never inspect, print, commit, or log sensitive environment secrets, keys, or passwords.

## 6. Testing and Verification Protocols

1. Every feature must have automated unit or integration tests verifying acceptance criteria.
2. Property-based tests must validate core mathematical/idempotence invariants.
3. Verification commands:
   - Mobile: `flutter analyze` and `flutter test` (run within `mobile/`). Note: Linux test environments require SQLite dynamic library (`libsqlite3.so` / `libsqlite3.so.0`).
   - Backend: `pytest` and `ruff check` (run within `backend/`).
4. Never weaken or bypass tests simply to make them pass.

## 7. Git and Change Safety

1. Inspect `git status` before making changes.
2. Keep edits narrowly focused on the assigned task.
3. Never execute destructive Git commands (`git reset --hard`, force-push, branch deletion).
4. Do not commit or push unless explicitly requested by the user.

## 8. Standardized Completion Report

At the end of each logical unit of work, provide a report structured as follows:

### Task
- ID and title.
- Status: Completed / Partially completed / Blocked / Needs review.

### Implementation
- Summary of behavior added or changed.
- Important files modified.

### Verification
- Commands and tests executed.
- Pass/fail results and output.
- Checks not executed with rationale.

### Specification Synchronization
- Updates to `tasks.md`, `requirements.md`, or `design.md`.

### Remaining Work
- Known gaps, blockers, or next recommended task.
