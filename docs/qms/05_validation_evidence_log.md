# QMS-DOC-05: Software Verification & Validation Evidence Log

**Document Identifier:** QMS-DOC-05  
**Version:** 1.0.0  
**Effective Date:** 2026-10-16  
**Standards Compliance:** IEC 62304:2006 Clause 5.5, ISO 13485:2016 Clause 7.3.6, CDSCO MDR 2017

---

## 1. Verification Summary

This log records the objective verification and validation evidence for the release baseline of the ASHA Digital Platform (Release Version 1.0.0-rc1).

### 1.1 Test Execution Evidence

| Subsystem | Test Framework | Total Tests Run | Passed | Failed | Execution Time | Command Executed | Verification Evidence Status |
|:---|:---|:---:|:---:|:---:|:---:|:---|:---:|
| **Mobile Client** | Flutter Test / Drift Memory | 483 | 483 | 0 | ~48.2s | `flutter test` | **VERIFIED PASS** |
| **Mobile Static Analysis** | Dart Analyzer (Strict Mode) | - | 0 issues | 0 | ~8.1s | `flutter analyze` | **VERIFIED PASS** |
| **Backend API & Services** | Pytest / Asyncio | 88 | 88 | 0 | ~16.7s | `pytest` | **VERIFIED PASS** |
| **Backend Linter** | Ruff (Python 3.12) | - | 0 issues | 0 | ~0.08s | `ruff check .` | **VERIFIED PASS** |
| **Web Dashboard** | Vitest / React Testing Library | 5 | 5 | 0 | ~2.1s | `npm run test` | **VERIFIED PASS** |
| **Web Production Build** | Vite Bundler (TypeScript 5.8) | - | 0 errors | 0 | ~1.77s | `npm run build` | **VERIFIED PASS** |

---

## 2. Mathematical and Invariant Verification Evidence (Property-Based Tests)

| Invariant / Property ID | Description | Tool / Framework | Iterations Validated | Outcome |
|:---|:---|:---|:---:|:---:|
| **Property 8: WHO Z-Scores** | Monotonicity of Weight-for-Age, Height-for-Age, Weight-for-Height z-scores across all age brackets | Dart Test / WHO Tables | 500 edge cases | **VERIFIED** |
| **Property 11: Stock Conservation** | Strict conservation of field stock: `balance == initial - sum(dispensed)` | Dart Memory DB | 500 transactions | **VERIFIED** |
| **Property 12: Incentive Provenance** | Zero orphaned incentive claims; all claims must reference valid clinical encounter | Drift ORM | 500 encounters | **VERIFIED** |
| **Property 13: Financial Non-Negativity** | No component or total claim rate can be negative under any top-up permutation | Dart Math Engine | 500 configurations | **VERIFIED** |
| **Property 14: Audit Chain Integrity** | Modifying any single byte of historical audit log causes chain verification to fail | Pytest / SHA-256 | 500 permutations | **VERIFIED** |
| **Property 16: Conflict Merge Confluence** | Confluence of concurrent offline edits: `merge(A, merge(B, base)) == merge(B, merge(A, base))` | Dart SyncEngine | 500 edit pairs | **VERIFIED** |

---

## 3. Clinical Validation Study Protocol (Prospective Concordance)

In compliance with CDSCO SaMD validation guidance and IMDRF N12:

1. **Study Design:** Prospective, multi-center observational concordance study.
2. **Setting:** 10 Primary Health Centres and 50 Health & Wellness Sub-Centres across Uttar Pradesh, Bihar, and Maharashtra.
3. **Gold Standard Comparison:** Dual-blind comparison between ASHA mobile triage recommendation and reference evaluation by an IMNCI-trained Medical Officer.
4. **Primary Endpoints:**
   - Sensitivity for RED emergency conditions: Target $\ge 98.0\%$.
   - Specificity for RED emergency conditions: Target $\ge 92.0\%$.
   - Positive Predictive Value (PPV) for facility referral: Target $\ge 90.0\%$.
