# QMS-DOC-06: Complaint Handling & Vigilance Reporting Procedure

**Document Identifier:** QMS-DOC-06  
**Version:** 1.0.0  
**Effective Date:** 2026-10-16  
**Standards Compliance:** CDSCO MDR 2017 (Rules 64–67), ISO 13485:2016 Clause 8.2.2, ISO 14971:2019 Clause 10

---

## 1. Purpose & Scope

This SOP specifies the protocol for receiving, recording, triaging, investigating, and reporting complaints, safety incidents, near misses, and adverse events associated with the ASHA Digital Platform.

It defines the mandatory timeline and format for reporting reportable adverse events to the Central Drugs Standard Control Organisation (CDSCO) and the National Health Mission (NHM).

---

## 2. Event Classification & Regulatory Reporting Timelines

| Event Severity | Description | Reporting Destination | Statutory Timeline | Form / Channel |
|:---|:---|:---|:---:|:---:|
| **Critical Adverse Event (Life-Threatening / Death)** | Software error contributed directly or indirectly to patient death, fetal demise, or irreversible impairment (e.g. failure to trigger pre-eclampsia alert). | **CDSCO Central Licensing Authority + State Mission Director** | **Within 48 Hours** of initial awareness | **CDSCO Form MD-28 / MD-29** & Telephonic Notification |
| **Serious Adverse Event (Non-Fatal Hospitalization)** | Software defect caused delayed referral requiring emergency surgery, ICU admission, or prolonged hospitalization. | **CDSCO Central Licensing Authority** | **Within 15 Calendar Days** | **CDSCO Form MD-28** via SUGAM Portal |
| **Near Miss / Malfunction** | Software defect that *could* have led to serious injury if not intercepted by clinical human-in-the-loop oversight. | Internal Safety Committee + NHM State IT Cell | **Monthly Summary** (or quarterly PMS) | Internal Incident Log + Post-Market Surveillance Report |
| **Operational Complaint** | Equipment failure, sync delay, UI font rendering issue, or minor incentive discrepancy. | Local Block Health Center / Helpdesk | **Within 7 Working Days** | In-app Grievance Tracker (`WorkerPrivacyService`) |

---

## 3. Investigation & Corrective Action Procedure (CAPA)

1. **Receipt & Immediate Containment:**
   - On receipt of a suspected clinical safety incident, the Clinical Safety Officer immediately reviews the affected rule or component.
   - If a software calculation bug is verified, the **Backend AI Safety Service Killswitch** is invoked (`disable_component()`) to immediately disable the offending rule/component nationwide and revert devices to conservative manual triage.

2. **Root Cause Analysis (RCA):**
   - The Engineering Lead performs RCA on the isolated stack trace, input logs, and rule engine state.
   - 5-Whys methodology is applied to determine root cause (e.g. unexpected null value in blood pressure parser).

3. **Corrective and Preventive Action (CAPA):**
   - Implement software fix with regression test coverage.
   - Execute QMS Change Control procedure (`QMS-DOC-04`).
   - Dual sign-off by Technical Lead and Clinical Safety Officer.

4. **Vigilance Final Report:**
   - Complete investigation report submitted to CDSCO within 30 days of the initial notification, detailing root cause, CAPA actions taken, and verification evidence.
