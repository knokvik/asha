# Risk model report

Synthetic assessments: 50,000. Seed 7. Each row is labeled by the IMCI / IMNCI rule tables in `imci_engine`, not by a clinician. The split is 70% train, 15% isotonic calibration, 15% holdout.

Label counts: GREEN 18604, YELLOW 16183, RED 15213.

Features are the assessment fields, missingness indicators for respiratory rate, temperature, and weight-for-age Z, sex, and the three synthetic NFHS-5 district priors. The list is `feature_spec.json`.

| Model | Multiclass Brier | Red Brier | Red AUC | Red sensitivity at p_red 0.5 |
| --- | ---: | ---: | ---: | ---: |
| Logistic regression, isotonic on p_red | 0.1504 | 0.0262 | 0.9785 | 0.9141 |
| LightGBM, isotonic on p_red | 0.0753 | 0.0085 | 0.986 | 0.972 |

Selected model: **lightgbm** (lower holdout Brier). Escalation threshold stays 0.65, as set for the hybrid policy. A probability sitting on 0.65 does not escalate.

Logistic regression stopped at its iteration cap, so its row is a lower bound on that model, not a fully converged fit. The gap to LightGBM is large enough that another pass would not change the selection. LightGBM wins because the chart cutoffs are interactions (age band and respiratory rate) that a single linear layer only approximates.

On-device artifact: `lib/data/model/model.json`, 167727 bytes. The linear layer is stored as int8 coefficients with scale 0.084940. LightGBM trees are stored only when that model wins. A Python walk of those trees matches `predict_proba` within 0.00e+00 on 30 holdout rows.

Latency: about 0.004 ms per LightGBM `predict_proba` on this machine for one row, measured as the mean of 4,000 rows. The phone runs the same trees in Dart. The acceptance bar is a p95 under 50 ms.

This environment has no TensorFlow install, so there is no separate `.tflite` binary. The int8 coefficient table is the fully connected layer that file would contain, and `RiskModel` executes it. `tflite_flutter` can replace that call later without changing `feature_names`.

The model is not allowed to lower a RED or raise a GREEN. Those rules are in `HybridTriage`, not in the weights.
