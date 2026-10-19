# triage

Offline adaptive loop for one ASHA visit. Pure Dart. No Flutter widget, no
network import. `imci_engine` is a separate package so the chart rules stay
free of this pack loader and can be tested on their own.

Two packages, on purpose:

- `imci_engine` evaluates the WHO chart. It does not know which ward the ASHA is in.
- `triage` loads a context pack, chooses outbreak modules, orders the questions,
  and applies the hybrid policy. The phone passes in strings it already cached.

## What a pack contains

`lib/data/pack/` is the demo pack for Pimpri-Chinchwad. Eight sample wards,
twelve weeks of synthetic IDSP-style counts, four outbreak modules, and fake
NFHS-5 priors. `ml/generate_pack.py` rewrites it.

Ward W3's dengue-like counts over the last four weeks are 1, 2, 3, 5. A module
turns on when the month is in its season and the peak week in the look-back is
at least `min_cases_per_week`. In October that is dengue in W3 only.
`disease_counts_v2.csv` is the next pack: those counts move to W5.

The polygons are a grid, not official boundaries. There is no live GPS call.
The app passes the last cached fix. Within 50 metres of a boundary the worker
confirms the ward. With no fix, she picks from the list.

Priors are synthetic. Replace them with the NFHS-5 district fact sheet:

- children age 6–59 months who are anaemic (<11.0 g/dl) (%)
- children under 5 who are stunted (height-for-age) (%)
- children age 12–23 months fully vaccinated (card or mother's recall) (%)

PCMC sits inside Pune district.

## Question order

1. The five general danger signs, in chart order. The drink question is
   "Can the child drink or breastfeed?" Yes means the child can drink, so the
   stored field `symptoms.unable_to_drink` is inverted.
2. Red-flag questions of outbreak modules that are active for this ward.
3. The rest of the IMCI core, highest weight first.
4. The remaining outbreak questions.

The core set is in every flow. A confirmed danger sign stops further questions.
Unknown stores nothing, so a missing danger sign is not treated as No.

`FlowState.toAssessmentInput` builds the object `ImciEngine.evaluate` reads.

## Hybrid flag

`HybridTriage.combine` keeps an engine RED. It keeps an engine GREEN. It raises
a YELLOW to RED only when the model's red probability is above 0.65, and the
reason includes the ward's outbreak sentence. Follow-up days are cleared on
that escalation because the child is being referred now.

## Loop

`AdaptiveTriage.updateContextPack` rejects an older version, drops the open
flow, and the next `openAssessment` recomputes modules. `enqueue` appends an
`OutboxItem`. The server module, not this package, posts that queue, sums the
week's ward counts, and publishes the next pack.

## Model

`ml/train_risk_model.py` samples assessments, labels them with the same rule
tables, and fits logistic regression and LightGBM. The better-calibrated model
is what `RiskModel` runs. Weights are int8 for the linear layer. There is no
network and no TFLite plugin on this path; the app can swap in `tflite_flutter`
later using `feature_names` in the same order. Scoring stays on the phone.
