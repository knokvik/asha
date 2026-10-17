# QMS-DOC-04: Clinical Software Change Control Procedure

**Document Identifier:** QMS-DOC-04  
**Version:** 1.0.0  
**Effective Date:** 2026-10-16  
**Standards Compliance:** IEC 62304:2006 Clause 8, ISO 13485:2016 Clause 7.3.9, CDSCO MDR 2017

---

## 1. Purpose & Scope

This Standard Operating Procedure (SOP) governs all proposed modifications, bug fixes, enhancements, rule updates, and architectural changes to the ASHA Digital Platform codebase.

The procedure ensures that any change affecting clinically relevant behavior (such as triage logic, dose scheduling, drug dispensing, or referral routing) undergoes rigorous risk assessment, regression testing, and authorized clinical sign-off prior to production release.

---

## 2. Change Control Workflow

```
[Change Request (CR) Filed]
           │
           ▼
[Clinical Safety Impact Assessment]
           │
           ├─► No Clinical Impact ──► Standard Technical Review
           │
           ▼ (Clinically Relevant)
[Risk Management Review (Hazard Analysis Update)]
           │
           ▼
[Implementation & Targeted Unit / Property Tests]
           │
           ▼
[Full Automated Regression Test Suite (Mobile, Backend, Dashboard)]
           │
           ▼
[Multidisciplinary Sign-Off: Tech Lead + Clinical Safety Officer]
           │
           ▼
[Version Increment & Staged Staging Deployment]
```

---

## 3. Detailed Steps

### Step 1: Change Request (CR) Initiation
Every change must be logged in the project repository tracking system with:
1. Unique CR Identifier.
2. Requirement Tracing: ID of the system requirement being modified.
3. Rationale: Clinical guideline change, reported defect, regulatory update, or performance tuning.

### Step 2: Clinical Impact Analysis
Before any code edit, the Engineering Team and Clinical Reviewer must classify the change:
- **Major Clinical Change:** Modifies triage thresholds, adds new danger signs, alters drug dosage/dispensation rules, or updates immunization timelines.
- **Minor Clinical Change:** Updates wording in educational job aids, adds new translated audio prompts without changing clinical meaning.
- **Non-Clinical Change:** Performance refactoring, UI layout polish, database indexing, infrastructure configuration.

### Step 3: Hazard & Risk Update (ISO 14971)
If the change is classified as Major or Minor Clinical:
1. Review `QMS-DOC-03 (Risk Management File)`.
2. Determine whether the change introduces any new hazards (e.g. risk of false-negative triage) or affects existing risk controls.
3. Document any newly required risk controls.

### Step 4: Verification Protocols
Every change must satisfy the following automated verification gates:
1. **Targeted Unit Tests:** 100% pass rate on all tests in the affected module.
2. **Property-Based Invariants:** Full execution of core property tests (monotone z-scores, idempotent incentives, audit chain integrity).
3. **Full Regression Suite:**
   - Mobile: `flutter analyze` (0 issues) and `flutter test` (all suites passing).
   - Backend: `ruff check .` (0 issues) and `pytest` (all suites passing).
   - Web Dashboard: `npm run build` and `vitest` (all suites passing).

### Step 5: Dual Authority Release Sign-Off
No release artifact (APK patch, Docker container, or OTA rule bundle) may be published without documented sign-off from:
1. **Technical Lead:** Verifies code architecture, test coverage, and security safeguards.
2. **Clinical Safety Officer (MD / Public Health Specialist):** Verifies adherence to MoHFW national clinical guidelines and patient safety invariants.
