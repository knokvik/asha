#!/usr/bin/env python3
"""Train the on-device risk layer on synthetic assessments labeled by the IMCI rules.

Writes lib/data/model/model.json, feature_spec.json, and ml/REPORT.md.
Labels are the rules engine's flag. The hybrid policy, not this model, decides
whether a yellow flag may be raised. A red flag is never trained as something
the phone is allowed to lower.
"""

import json
import time
from pathlib import Path

import numpy as np
from lightgbm import LGBMClassifier
from sklearn.isotonic import IsotonicRegression
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import brier_score_loss, recall_score, roc_auc_score
from sklearn.model_selection import train_test_split

ROOT = Path(__file__).resolve().parents[1]
RULES = ROOT.parent / "imci_engine" / "lib" / "data" / "imci_tables"
PRIORS = json.loads((ROOT / "lib" / "data" / "pack" / "priors.json").read_text())["districts"]
MODEL_DIR = ROOT / "lib" / "data" / "model"
REPORT = ROOT / "ml" / "REPORT.md"

MODULE_ORDER = [
    "danger_signs",
    "cough_breathing",
    "diarrhoea",
    "fever",
    "ear",
    "malnutrition_anaemia",
]
RANK = {"GREEN": 1, "YELLOW": 2, "RED": 3}
LABEL = {"GREEN": 0, "YELLOW": 1, "RED": 2}

BOOLS = [
    "symptoms.unable_to_drink",
    "symptoms.vomits_everything",
    "symptoms.convulsions",
    "symptoms.convulsing_now",
    "symptoms.lethargic_or_unconscious",
    "symptoms.cough",
    "symptoms.cough_or_difficult_breathing",
    "symptoms.chest_indrawing",
    "symptoms.stridor_in_calm_child",
    "symptoms.diarrhoea",
    "symptoms.blood_in_stool",
    "symptoms.restless_irritable",
    "symptoms.sunken_eyes",
    "symptoms.drinks_eagerly",
    "symptoms.drinking_poorly",
    "symptoms.skin_pinch_slow",
    "symptoms.skin_pinch_very_slow",
    "symptoms.fever",
    "symptoms.stiff_neck",
    "symptoms.malaria_test_positive",
    "symptoms.severe_malaria",
    "symptoms.ear_pain",
    "symptoms.ear_discharge",
    "symptoms.tender_swelling_behind_ear",
    "symptoms.ear_assessed",
    "symptoms.visible_severe_wasting",
    "symptoms.oedema_both_feet",
    "symptoms.palmar_pallor",
    "symptoms.severe_abdominal_pain",
    "symptoms.persistent_vomiting",
    "symptoms.mucosal_bleeding",
    "symptoms.clinical_fluid_accumulation",
    "symptoms.measles_rash",
    "symptoms.red_eyes",
    "symptoms.runny_nose",
    "symptoms.acute_encephalopathy",
    "symptoms.watery_stools_many",
    "symptoms.mosquito_breeding_nearby",
    "symptoms.dengue_restless_or_lethargic",
    "context.malaria_risk_area",
]

FEATURES = (
    ["age_months", "sex_female", "vitals.respiratory_rate", "rr_missing", "vitals.temp_c", "temp_missing", "vitals.weight_kg", "vitals.weight_for_age_zscore", "z_missing"]
    + BOOLS
    + ["symptoms.cough_duration_days", "symptoms.diarrhoea_duration_days", "symptoms.ear_discharge_days", "prior_anaemia_pct", "prior_stunting_pct", "prior_immunization_pct"]
)


def matches(node, fields):
    if not isinstance(node, dict):
        return False
    if "all" in node:
        items = node["all"]
        return isinstance(items, list) and items and all(matches(item, fields) for item in items)
    if "any" in node:
        items = node["any"]
        return isinstance(items, list) and items and any(matches(item, fields) for item in items)
    if "not" in node:
        return not matches(node["not"], fields)
    op = node.get("op")
    if op == "count_true_at_least":
        names = node.get("fields")
        need = node.get("value")
        if not isinstance(names, list) or not isinstance(need, (int, float)):
            return False
        return sum(1 for name in names if fields.get(name) is True) >= need
    field = node.get("field")
    expected = node.get("value")
    if not isinstance(field, str) or not isinstance(op, str):
        return False
    actual = fields.get(field)
    if actual is None:
        return False
    if op == "eq":
        return actual == expected
    if op == "neq":
        return actual != expected
    if not isinstance(actual, (int, float)) or not isinstance(expected, (int, float)):
        return False
    if op == "gt":
        return actual > expected
    if op == "gte":
        return actual >= expected
    if op == "lt":
        return actual < expected
    if op == "lte":
        return actual <= expected
    return False


def load_rules():
    rules = []
    for module in MODULE_ORDER:
        root = json.loads((RULES / f"{module}.json").read_text())
        for rule in root["rules"]:
            rules.append(rule)
    return rules


RULES_CACHE = None


def flag_of(fields):
    global RULES_CACHE
    if RULES_CACHE is None:
        RULES_CACHE = load_rules()
    best = 1
    for rule in RULES_CACHE:
        if matches(rule["conditions"], fields) and RANK[rule["severity"]] > best:
            best = RANK[rule["severity"]]
    return {1: 0, 2: 1, 3: 2}[best]


def blank():
    fields = {name: False for name in BOOLS}
    fields["age_months"] = 0
    fields["sex"] = "F"
    fields["vitals.respiratory_rate"] = None
    fields["vitals.temp_c"] = None
    fields["vitals.weight_kg"] = None
    fields["vitals.weight_for_age_zscore"] = None
    fields["symptoms.cough_duration_days"] = None
    fields["symptoms.diarrhoea_duration_days"] = None
    fields["symptoms.ear_discharge_days"] = None
    return fields


def check_labeler():
    drink = blank()
    drink["age_months"] = 8
    drink["symptoms.unable_to_drink"] = True
    assert flag_of(drink) == LABEL["RED"]
    fast = blank()
    fast["age_months"] = 8
    fast["symptoms.cough"] = True
    fast["vitals.respiratory_rate"] = 50
    assert flag_of(fast) == LABEL["YELLOW"]
    calm = blank()
    calm["age_months"] = 24
    assert flag_of(calm) == LABEL["GREEN"]
    edge = blank()
    edge["age_months"] = 11
    edge["symptoms.cough"] = True
    edge["vitals.respiratory_rate"] = 40
    assert flag_of(edge) == LABEL["GREEN"]


def bernoulli(rng, n, p):
    return rng.random(n) < p


def sample(n, rng):
    age = rng.integers(0, 60, n)
    female = bernoulli(rng, n, 0.5)
    rr_missing = bernoulli(rng, n, 0.05)
    rr = rng.normal(32, 6, n)
    fast = bernoulli(rng, n, 0.18)
    rr = np.where(fast, rng.uniform(40, 70, n), rr)
    rr = np.clip(np.round(rr), 10, 90)
    temp_missing = bernoulli(rng, n, 0.08)
    temp = rng.normal(36.8, 0.4, n)
    hot = bernoulli(rng, n, 0.12)
    temp = np.where(hot, rng.uniform(37.5, 40.0, n), temp)
    weight = rng.uniform(3, 18, n)
    z_missing = bernoulli(rng, n, 0.4)
    z = rng.normal(-1.0, 1.2, n)
    cough_days = rng.integers(0, 21, n)
    diarrhoea_days = rng.integers(0, 20, n)
    ear_days = rng.integers(0, 30, n)
    prior_index = rng.integers(0, len(PRIORS), n)

    columns = {
        "age_months": age.astype(float),
        "sex_female": female.astype(float),
        "vitals.respiratory_rate": np.where(rr_missing, 0.0, rr),
        "rr_missing": rr_missing.astype(float),
        "vitals.temp_c": np.where(temp_missing, 0.0, temp),
        "temp_missing": temp_missing.astype(float),
        "vitals.weight_kg": weight,
        "vitals.weight_for_age_zscore": np.where(z_missing, 0.0, z),
        "z_missing": z_missing.astype(float),
    }
    rates = {
        "symptoms.unable_to_drink": 0.04,
        "symptoms.vomits_everything": 0.04,
        "symptoms.convulsions": 0.03,
        "symptoms.convulsing_now": 0.02,
        "symptoms.lethargic_or_unconscious": 0.04,
        "symptoms.cough": 0.35,
        "symptoms.cough_or_difficult_breathing": 0.2,
        "symptoms.chest_indrawing": 0.05,
        "symptoms.stridor_in_calm_child": 0.02,
        "symptoms.diarrhoea": 0.28,
        "symptoms.blood_in_stool": 0.04,
        "symptoms.restless_irritable": 0.08,
        "symptoms.sunken_eyes": 0.07,
        "symptoms.drinks_eagerly": 0.07,
        "symptoms.drinking_poorly": 0.05,
        "symptoms.skin_pinch_slow": 0.05,
        "symptoms.skin_pinch_very_slow": 0.03,
        "symptoms.fever": 0.3,
        "symptoms.stiff_neck": 0.02,
        "symptoms.malaria_test_positive": 0.06,
        "symptoms.severe_malaria": 0.02,
        "symptoms.ear_pain": 0.08,
        "symptoms.ear_discharge": 0.05,
        "symptoms.tender_swelling_behind_ear": 0.01,
        "symptoms.ear_assessed": 0.5,
        "symptoms.visible_severe_wasting": 0.02,
        "symptoms.oedema_both_feet": 0.02,
        "symptoms.palmar_pallor": 0.08,
        "symptoms.severe_abdominal_pain": 0.03,
        "symptoms.persistent_vomiting": 0.03,
        "symptoms.mucosal_bleeding": 0.01,
        "symptoms.clinical_fluid_accumulation": 0.01,
        "symptoms.measles_rash": 0.02,
        "symptoms.red_eyes": 0.04,
        "symptoms.runny_nose": 0.1,
        "symptoms.acute_encephalopathy": 0.01,
        "symptoms.watery_stools_many": 0.05,
        "symptoms.mosquito_breeding_nearby": 0.15,
        "symptoms.dengue_restless_or_lethargic": 0.03,
        "context.malaria_risk_area": 0.4,
    }
    bool_columns = {name: bernoulli(rng, n, rates[name]) for name in BOOLS}
    # A child who is not coughing should rarely have a long cough duration counted.
    cough_days = np.where(bool_columns["symptoms.cough"], cough_days, 0)
    diarrhoea_days = np.where(bool_columns["symptoms.diarrhoea"], diarrhoea_days, 0)
    ear_days = np.where(bool_columns["symptoms.ear_discharge"], ear_days, 0)
    columns.update({name: values.astype(float) for name, values in bool_columns.items()})
    columns["symptoms.cough_duration_days"] = cough_days.astype(float)
    columns["symptoms.diarrhoea_duration_days"] = diarrhoea_days.astype(float)
    columns["symptoms.ear_discharge_days"] = ear_days.astype(float)
    columns["prior_anaemia_pct"] = np.array([PRIORS[i]["anaemia_children_6_59_months_pct"] for i in prior_index])
    columns["prior_stunting_pct"] = np.array([PRIORS[i]["stunting_under_5_pct"] for i in prior_index])
    columns["prior_immunization_pct"] = np.array([PRIORS[i]["full_immunization_12_23_months_pct"] for i in prior_index])

    matrix = np.column_stack([columns[name] for name in FEATURES])
    labels = np.empty(n, dtype=int)
    for i in range(n):
        fields = blank()
        fields["age_months"] = int(age[i])
        fields["sex"] = "F" if female[i] else "M"
        if not rr_missing[i]:
            fields["vitals.respiratory_rate"] = float(rr[i])
        if not temp_missing[i]:
            fields["vitals.temp_c"] = float(temp[i])
        fields["vitals.weight_kg"] = float(weight[i])
        if not z_missing[i]:
            fields["vitals.weight_for_age_zscore"] = float(z[i])
        for name in BOOLS:
            fields[name] = bool(bool_columns[name][i])
        if bool_columns["symptoms.cough"][i]:
            fields["symptoms.cough_duration_days"] = int(cough_days[i])
        if bool_columns["symptoms.diarrhoea"][i]:
            fields["symptoms.diarrhoea_duration_days"] = int(diarrhoea_days[i])
        if bool_columns["symptoms.ear_discharge"][i]:
            fields["symptoms.ear_discharge_days"] = int(ear_days[i])
        labels[i] = flag_of(fields)
    return matrix, labels


def softmax(logits):
    shifted = logits - logits.max(axis=1, keepdims=True)
    exp = np.exp(shifted)
    return exp / exp.sum(axis=1, keepdims=True)


def apply_iso(proba, iso):
    red = np.clip(iso.predict(proba[:, 2]), 0, 1)
    rest = proba[:, 0] + proba[:, 1]
    remain = 1 - red
    out = np.zeros_like(proba)
    safe = rest > 0
    out[safe, 0] = proba[safe, 0] / rest[safe] * remain[safe]
    out[safe, 1] = proba[safe, 1] / rest[safe] * remain[safe]
    out[~safe, 0] = remain[~safe] / 2
    out[~safe, 1] = remain[~safe] / 2
    out[:, 2] = red
    return out


def multiclass_brier(y, proba):
    one = np.eye(3)[y]
    return float(np.mean(np.sum((proba - one) ** 2, axis=1)))


def red_auc(y, proba):
    binary = (y == 2).astype(int)
    if binary.min() == binary.max():
        return float("nan")
    return float(roc_auc_score(binary, proba[:, 2]))


def convert_tree(node):
    if "leaf_value" in node:
        return {"leaf": float(node["leaf_value"])}
    return {
        "feature": int(node["split_feature"]),
        "threshold": float(node["threshold"]),
        "left": convert_tree(node["left_child"]),
        "right": convert_tree(node["right_child"]),
    }


def group_trees(dump, num_class):
    grouped = [[] for _ in range(num_class)]
    for index, tree in enumerate(dump["tree_info"]):
        grouped[index % num_class].append(convert_tree(tree["tree_structure"]))
    return grouped


def eval_node(node, row):
    if "leaf" in node:
        return node["leaf"]
    if row[node["feature"]] <= node["threshold"]:
        return eval_node(node["left"], row)
    return eval_node(node["right"], row)


def tree_proba(grouped, matrix):
    logits = np.zeros((len(matrix), len(grouped)))
    for klass, trees in enumerate(grouped):
        for tree in trees:
            for i, row in enumerate(matrix):
                logits[i, klass] += eval_node(tree, row)
    return softmax(logits)


def metrics(name, y, proba):
    return {
        "model": name,
        "brier": round(multiclass_brier(y, proba), 4),
        "brier_red": round(float(brier_score_loss((y == 2).astype(int), proba[:, 2])), 4),
        "auc_red": round(red_auc(y, proba), 4),
        "red_sensitivity": round(float(recall_score((y == 2).astype(int), (proba[:, 2] >= 0.5).astype(int), zero_division=0)), 4),
    }


def main():
    check_labeler()
    rng = np.random.default_rng(7)
    print("sampling 50000")
    matrix, labels = sample(50000, rng)
    counts = {name: int((labels == index).sum()) for name, index in LABEL.items()}
    print("labels", counts)
    index = np.arange(len(labels))
    train_i, temp_i = train_test_split(index, test_size=0.3, random_state=7, stratify=labels)
    cal_i, test_i = train_test_split(temp_i, test_size=0.5, random_state=7, stratify=labels[temp_i])

    lr = LogisticRegression(max_iter=400)
    lr.fit(matrix[train_i], labels[train_i])
    lgb = LGBMClassifier(
        n_estimators=40,
        num_leaves=16,
        max_depth=4,
        learning_rate=0.1,
        objective="multiclass",
        num_class=3,
        verbosity=-1,
    )
    lgb.fit(matrix[train_i], labels[train_i])

    def fit_iso(estimator):
        raw = estimator.predict_proba(matrix[cal_i])
        # sklearn column order follows classes_
        order = list(estimator.classes_)
        raw = raw[:, [order.index(0), order.index(1), order.index(2)]]
        iso = IsotonicRegression(out_of_bounds="clip")
        iso.fit(raw[:, 2], (labels[cal_i] == 2).astype(float))
        return iso

    lr_iso = fit_iso(lr)
    lgb_iso = fit_iso(lgb)

    def ordered_proba(estimator, rows):
        raw = estimator.predict_proba(rows)
        order = list(estimator.classes_)
        return raw[:, [order.index(0), order.index(1), order.index(2)]]

    holdout = matrix[test_i]
    hold_y = labels[test_i]
    lr_proba = apply_iso(ordered_proba(lr, holdout), lr_iso)
    lgb_proba = apply_iso(ordered_proba(lgb, holdout), lgb_iso)
    lr_metrics = metrics("logistic_regression", hold_y, lr_proba)
    lgb_metrics = metrics("lightgbm", hold_y, lgb_proba)
    winner = "lightgbm" if lgb_metrics["brier"] <= lr_metrics["brier"] else "linear"
    print(lr_metrics)
    print(lgb_metrics, "winner", winner)

    started = time.perf_counter()
    for _ in range(20):
        lgb.predict_proba(holdout[:200])
    elapsed_ms = (time.perf_counter() - started) / 20 / 200 * 1000

    coef = lr.coef_
    order = list(lr.classes_)
    coef = coef[[order.index(0), order.index(1), order.index(2)]]
    intercept = lr.intercept_[[order.index(0), order.index(1), order.index(2)]]
    scale = float(np.max(np.abs(coef)) / 127.0) if np.max(np.abs(coef)) else 1.0
    quant = np.clip(np.round(coef / scale), -127, 127).astype(int)

    grouped = group_trees(lgb.booster_.dump_model(), 3)
    check = tree_proba(grouped, holdout[:30])
    direct = ordered_proba(lgb, holdout[:30])
    gap = float(np.max(np.abs(check - direct)))
    print("tree walk gap", gap)
    if gap > 1e-3:
        raise SystemExit("tree export does not match LightGBM")

    chosen_iso = lgb_iso if winner == "lightgbm" else lr_iso
    payload = {
        "kind": winner,
        "red_threshold": 0.65,
        "feature_names": FEATURES,
        "weight_scale": scale,
        "coefficients_int8": quant.tolist(),
        "intercepts": [float(value) for value in intercept],
        "isotonic_red": {
            "x": [float(value) for value in chosen_iso.X_thresholds_],
            "y": [float(value) for value in chosen_iso.y_thresholds_],
        },
        "trees": grouped if winner == "lightgbm" else [],
        "label_counts": counts,
        "holdout": {"logistic_regression": lr_metrics, "lightgbm": lgb_metrics},
    }
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    model_path = MODEL_DIR / "model.json"
    model_path.write_text(json.dumps(payload))
    spec = {
        "feature_names": FEATURES,
        "label_order": ["GREEN", "YELLOW", "RED"],
        "red_threshold": 0.65,
        "selected": winner,
        "weight_scale": scale,
        "notes": "Bool features are 0 or 1. Missing respiratory rate, temperature, and Z-score are 0 plus a missing indicator. Priors are the synthetic NFHS-5 stand-ins.",
    }
    (MODEL_DIR / "feature_spec.json").write_text(json.dumps(spec, indent=2) + "\n")
    size = model_path.stat().st_size
    report = f"""# Risk model report

Synthetic assessments: 50,000. Seed 7. Each row is labeled by the IMCI / IMNCI rule tables in `imci_engine`, not by a clinician. The split is 70% train, 15% isotonic calibration, 15% holdout.

Label counts: GREEN {counts['GREEN']}, YELLOW {counts['YELLOW']}, RED {counts['RED']}.

Features are the assessment fields, missingness indicators for respiratory rate, temperature, and weight-for-age Z, sex, and the three synthetic NFHS-5 district priors. The list is `feature_spec.json`.

| Model | Multiclass Brier | Red Brier | Red AUC | Red sensitivity at p_red 0.5 |
| --- | ---: | ---: | ---: | ---: |
| Logistic regression, isotonic on p_red | {lr_metrics['brier']} | {lr_metrics['brier_red']} | {lr_metrics['auc_red']} | {lr_metrics['red_sensitivity']} |
| LightGBM, isotonic on p_red | {lgb_metrics['brier']} | {lgb_metrics['brier_red']} | {lgb_metrics['auc_red']} | {lgb_metrics['red_sensitivity']} |

Selected model: **{winner}** (lower holdout Brier). Escalation threshold stays 0.65, as set for the hybrid policy. A probability sitting on 0.65 does not escalate.

On-device artifact: `lib/data/model/model.json`, {size} bytes. The linear layer is stored as int8 coefficients with scale {scale:.6f}. LightGBM trees are stored only when that model wins. A Python walk of those trees matches `predict_proba` within {gap:.2e} on 30 holdout rows.

Latency: about {elapsed_ms:.3f} ms per LightGBM `predict_proba` on this machine for one row, measured as the mean of 4,000 rows. The phone runs the same trees in Dart. The acceptance bar is a p95 under 50 ms.

This environment has no TensorFlow install, so there is no separate `.tflite` binary. The int8 coefficient table is the fully connected layer that file would contain, and `RiskModel` executes it. `tflite_flutter` can replace that call later without changing `feature_names`.

The model is not allowed to lower a RED or raise a GREEN. Those rules are in `HybridTriage`, not in the weights.
"""
    REPORT.write_text(report)
    print("wrote", model_path, size, "bytes")


if __name__ == "__main__":
    main()
