# Changelog

## Unreleased

- Triage input safety: added plausibility guardrails for temperature, respiratory
  rate, pulse, and blood pressure, plus a systolic/diastolic cross-measure check.
  Values outside the guardrail require explicit worker confirmation; no triage
  severity threshold or question scoring was changed.
- Triage measurement UX: added a real 60-second respiratory-rate timer with an
  optional tap-to-count control that fills the rate field when complete.
- Triage flow UX: exact age-in-days is shown only for children under two years;
  patient context is required; intake-derived answers are marked for review;
  protocol and area-signal labels are visible; neutral answer buttons and
  offline "How to check" guidance were added for difficult signs.
- Triage nutrition input: weight is ordered before weight-for-age Z-score and
  the existing bundled WHO LMS calculator derives the Z-score offline when sex
  and age support the lookup. The derived value is shown as calculated rather
  than entered by the worker.
- `NEEDS CLINICIAN VALIDATION`: confirm the plausibility ranges against the
  currently approved field protocols before production release. Weight-for-age
  derived scoring uses the existing bundled WHO tables and still needs clinical
  sign-off before release. The new voice vocabulary/help illustrations remain
  TODO; no runtime assets were downloaded.
