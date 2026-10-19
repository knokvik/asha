# imci_engine

On-device WHO IMCI (2–59 months) and IMNCI (0–2 months) classifier. Pure Dart.
No Flutter, no files, no network. The app loads the JSON and passes the maps in.

`ImciEngine.evaluate` returns an `EngineResult` (the same object as `TriageResult`):
the overall flag, every fired rule, and the follow-up day count from the rule
that set the flag.

## Rule file

One JSON file per module under `lib/data/imci_tables/`. The file has a `module`
name and a `rules` array. Each rule:

| Field | Meaning |
| --- | --- |
| `rule_id` | Stable id, for example `DS-DRINK`. |
| `module` | `danger_signs`, `cough_breathing`, `diarrhoea`, `fever`, `ear`, or `malnutrition_anaemia`. |
| `severity` | `RED`, `YELLOW`, or `GREEN`. |
| `reason_text` | An English string, or a map `{"en","hi","mr"}`. The engine shows `en`. |
| `guideline_ref` | Chart source, for example `IMCI chart booklet 2014, p.2`. |
| `suspected_disease` | Short label for the referral. |
| `follow_up_days` | Optional return visit. Pneumonia uses 2. Omitted on urgent referrals. |
| `actions` | Keys into the pre-referral sentences (`refer_urgently`, `first_dose_antibiotic`, `prevent_low_blood_sugar`, `ors`, `antimalarial`, `keep_warm`, `follow_up`). |
| `conditions` | A condition tree. See below. |

## Conditions

A condition is one JSON object.

- `{"all":[...]}` — every child matches. Empty is false.
- `{"any":[...]}` — one child matches. Empty is false.
- `{"not": <condition>}` — the child does not match.
- `{"field","op","value"}` — compare one assessment field.
  `op` is `eq`, `neq`, `gt`, `gte`, `lt`, or `lte`.
- `{"op":"count_true_at_least","fields":[...],"value":2}` — at least `value` of those fields are true.

A missing number does not match a comparison. A missing bool is false. Bool
fields from `AssessmentInput.toFields()` are always present.

Field names match `AssessmentInput.toFields()`, for example
`age_months`, `vitals.respiratory_rate`, `symptoms.chest_indrawing`.

## How a flag is chosen

Rules run in this module order: danger signs, cough, diarrhoea, fever, ear,
malnutrition. Inside a file they run from top to bottom.

If `context.active_modules` is empty, or it only names modules this catalog
does not have (outbreak modules such as `dengue`), every chart module runs.
If it names chart modules, danger signs still run, and the other chart modules
run only when they are listed.

The highest severity wins (`RED` over `YELLOW` over `GREEN`). Every fired rule
is returned, including the milder ones. Follow-up days come from the first
rule that reached that winning severity. No fired rule means `GREEN`.

## Cutoffs encoded here

- Fast breathing, cough or difficult breathing: 2–11 months at 50 breaths/min
  or more; 12–59 months at 40 or more. The count is included (`>=`).
- Age under 2 months: 60 breaths/min or more is RED (IMNCI). Temperature
  37.5 C or higher, or below 35.5 C, is RED.
- Cough longer than 14 days, with no fast breathing, indrawing, or stridor,
  is the green follow-up category. Exactly 14 days is not that category.
- Diarrhoea for 14 days or more is persistent (yellow).
- Severe dehydration is two or more of: lethargic, sunken eyes, drinks poorly,
  skin pinch very slow. Some dehydration is two or more of: restless, sunken
  eyes, drinks eagerly, skin pinch slow, and not the severe set.
- Dysentery is yellow on its own and red when a general danger sign is also present.
- Weight-for-age Z below -3 is severe. From -3 through -2, including both ends,
  is moderate.
- A very slow skin pinch does not also set the slow pinch. The caller decides.

## Referral note

`ReferralNote.fromResult` builds the note. `toMarkdown()` is the full note.
`toSms()` is one line, at most 160 characters:

`REF|<id>|<FLAG>|<age>m|<sex>|RR<rate>|T<temp>|<up to 3 rule ids>|<ward>`

The line has no child name and no phone number. `toFhirBundle()` is an R4
document Bundle with Patient, Encounter, Observation (for measured vitals),
and one Condition per fired rule. The ABHA system is
`https://healthid.ndhm.gov.in`. `suggestedFacilityId` stays null until a maps
module fills it.

This package does not choose a ward, ask questions, or score a model. Those
live in the `triage` package.
