#!/usr/bin/env python3
"""Write the demo PCMC context pack. All people, counts, and priors are synthetic.

Run from anywhere:
  python3 ml/generate_pack.py
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "data" / "pack"
ROOT.mkdir(parents=True, exist_ok=True)

# 2 x 4 grid over a PCMC-like box. Not official ward boundaries.
LATS = [18.620, 18.660, 18.700]
LONS = [73.740, 73.780, 73.820, 73.860, 73.900]
WARD_AT = {
    "W1": (0, 0),
    "W2": (0, 1),
    "W3": (0, 2),
    "W4": (0, 3),
    "W5": (1, 0),
    "W6": (1, 1),
    "W7": (1, 2),
    "W8": (1, 3),
}


def ring(row, col):
    lat0, lat1 = LATS[row], LATS[row + 1]
    lon0, lon1 = LONS[col], LONS[col + 1]
    return [
        [lon0, lat0],
        [lon1, lat0],
        [lon1, lat1],
        [lon0, lat1],
        [lon0, lat0],
    ]


def geojson():
    features = []
    for ward, (row, col) in WARD_AT.items():
        features.append(
            {
                "type": "Feature",
                "properties": {"ward_id": ward, "name": f"PCMC sample ward {ward}"},
                "geometry": {"type": "Polygon", "coordinates": [ring(row, col)]},
            }
        )
    return {"type": "FeatureCollection", "features": features}


CONDITIONS = ["fever", "acute_diarrhoea", "measles_like", "dengue_like", "aes"]
WARDS = [f"W{i}" for i in range(1, 9)]


def baseline(ward_index, week, condition):
    if condition == "fever":
        return 2 + (ward_index + week) % 3
    if condition == "acute_diarrhoea":
        return 1 + (ward_index + week) % 2
    return 0


def counts(dengue_by_ward):
    lines = ["week_index,ward_id,condition,cases"]
    for week in range(1, 13):
        for index, ward in enumerate(WARDS):
            for condition in CONDITIONS:
                cases = baseline(index, week, condition)
                if condition == "dengue_like" and week >= 9:
                    series = dengue_by_ward.get(ward)
                    if series is not None:
                        cases = series[week - 9]
                lines.append(f"{week},{ward},{condition},{cases}")
    return "\n".join(lines) + "\n"


def question(qid, module, en, hi, mr, kind, weight, red, field, invert=False, numeric=None, options=None):
    item = {
        "id": qid,
        "module": module,
        "text": {"en": en, "hi": hi, "mr": mr},
        "type": kind,
        "weight": weight,
        "is_red_flag": red,
        "input_field": field,
    }
    if invert:
        item["invert_yes"] = True
    if numeric is not None:
        item["numeric"] = numeric
    if options is not None:
        item["options"] = options
    return item


def questions():
    rows = [
        question(
            "core.drink", "core",
            "Can the child drink or breastfeed?",
            "क्या बच्चा पानी पी या स्तनपान कर पा रहा है?",
            "मुलाला पाणी पिता येते का किंवा स्तनपान करता येते का?",
            "bool", 10, True, "symptoms.unable_to_drink", invert=True,
        ),
        question(
            "core.vomit", "core",
            "Does the child vomit everything?",
            "क्या बच्चा सब कुछ उगल देता है?",
            "मूल खाल्लेले सर्व उलटते का?",
            "bool", 10, True, "symptoms.vomits_everything",
        ),
        question(
            "core.convulsions", "core",
            "Has the child had convulsions during this illness?",
            "क्या इस बीमारी में बच्चे को दौरे पड़े हैं?",
            "या आजारात मुलाला झटके आले का?",
            "bool", 10, True, "symptoms.convulsions",
        ),
        question(
            "core.convulsing_now", "core",
            "Is the child convulsing now?",
            "क्या बच्चे को अभी दौरे पड़ रहे हैं?",
            "मुलाला आत्ता झटके येत आहेत का?",
            "bool", 10, True, "symptoms.convulsing_now",
        ),
        question(
            "core.lethargic", "core",
            "Is the child lethargic or unconscious?",
            "क्या बच्चा बहुत सुस्त या बेहोश है?",
            "मूल खूप सुस्त किंवा बेशुद्ध आहे का?",
            "bool", 10, True, "symptoms.lethargic_or_unconscious",
        ),
        question(
            "core.stiff_neck", "core",
            "Does the child have a stiff neck?",
            "क्या बच्चे की गर्दन अकड़ी हुई है?",
            "मुलाची मान ताठ आहे का?",
            "bool", 9, True, "symptoms.stiff_neck",
        ),
        question(
            "core.indrawing", "core",
            "Does the lower chest wall pull in when the child breathes in?",
            "क्या सांस लेते समय छाती अंदर धंसती है?",
            "श्वास घेताना छाती आत ओढली जाते का?",
            "bool", 8, True, "symptoms.chest_indrawing",
        ),
        question(
            "core.stridor", "core",
            "Is there a harsh sound when the child is calm?",
            "क्या शांत बच्चे की सांस में कर्कश आवाज है?",
            "मूल शांत असताना श्वासात खरखर आवाज आहे का?",
            "bool", 8, True, "symptoms.stridor_in_calm_child",
        ),
        question(
            "core.mastoid", "core",
            "Is there tender swelling behind the ear?",
            "क्या कान के पीछे दर्द के साथ सूजन है?",
            "कानामागे दाबले असता दुखणारी सूज आहे का?",
            "bool", 8, True, "symptoms.tender_swelling_behind_ear",
        ),
        question(
            "core.wasting", "core",
            "Does the child have visible severe wasting?",
            "क्या बच्चे में गंभीर कृशता दिखती है?",
            "मुलामध्ये गंभीर कृशता दिसते का?",
            "bool", 8, True, "symptoms.visible_severe_wasting",
        ),
        question(
            "core.oedema", "core",
            "Is there oedema of both feet?",
            "क्या दोनों पैरों पर सूजन है?",
            "दोन्ही पायावर सूज आहे का?",
            "bool", 8, True, "symptoms.oedema_both_feet",
        ),
        question(
            "core.rr", "core",
            "Count the breaths in one minute.",
            "एक मिनट में सांस गिनें।",
            "एका मिनिटातील श्वास मोजा.",
            "number", 8, False, "vitals.respiratory_rate",
            numeric={"unit": "/min", "min": 0, "max": 100, "decimals": 0},
        ),
        question(
            "core.severe_malaria", "core",
            "Are there signs of severe malaria?",
            "क्या गंभीर मलेरिया के लक्षण हैं?",
            "गंभीर मलेरियाची लक्षणे आहेत का?",
            "bool", 8, True, "symptoms.severe_malaria",
        ),
        question(
            "core.cough", "core",
            "Does the child have a cough or difficulty breathing?",
            "क्या बच्चे को खांसी या सांस लेने में तकलीफ है?",
            "मुलाला खोकला किंवा श्वास घेण्यास त्रास आहे का?",
            "bool", 7, False, "symptoms.cough",
        ),
        question(
            "core.diarrhoea", "core",
            "Does the child have diarrhoea?",
            "क्या बच्चे को दस्त हैं?",
            "मुलाला जुलाब आहे का?",
            "bool", 7, False, "symptoms.diarrhoea",
        ),
        question(
            "core.blood", "core",
            "Is there blood in the stool?",
            "क्या मल में खून है?",
            "शौचात रक्त आहे का?",
            "bool", 7, True, "symptoms.blood_in_stool",
        ),
        question(
            "core.fever", "core",
            "Does the child have fever?",
            "क्या बच्चे को बुखार है?",
            "मुलाला ताप आहे का?",
            "bool", 7, False, "symptoms.fever",
        ),
        question(
            "core.drinking_poorly", "core",
            "Is the child drinking poorly or not able to drink?",
            "क्या बच्चा बहुत कम पी पा रहा है?",
            "मूल फार कमी पीऊ शकते का?",
            "bool", 6, True, "symptoms.drinking_poorly",
        ),
        question(
            "core.cough_days", "core",
            "For how many days has the cough lasted?",
            "खांसी कितने दिन से है?",
            "खोकला किती दिवसांपासून आहे?",
            "number", 6, False, "symptoms.cough_duration_days",
            numeric={"unit": "days", "min": 0, "max": 60, "decimals": 0},
        ),
        question(
            "core.diarrhoea_days", "core",
            "For how many days has the diarrhoea lasted?",
            "दस्त कितने दिन से हैं?",
            "जुलाब किती दिवसांपासून आहे?",
            "number", 6, False, "symptoms.diarrhoea_duration_days",
            numeric={"unit": "days", "min": 0, "max": 60, "decimals": 0},
        ),
        question(
            "core.temp", "core",
            "What is the temperature?",
            "तापमान कितना है?",
            "तापमान किती आहे?",
            "number", 6, False, "vitals.temp_c",
            numeric={"unit": "C", "min": 32, "max": 43, "decimals": 1},
        ),
        question(
            "core.sunken", "core",
            "Are the eyes sunken?",
            "क्या आंखें धंसी हुई हैं?",
            "डोळे खोल गेले आहेत का?",
            "bool", 6, False, "symptoms.sunken_eyes",
        ),
        question(
            "core.restless", "core",
            "Is the child restless or irritable?",
            "क्या बच्चा बेचैन या चिड़चिड़ा है?",
            "मूल अस्वस्थ किंवा चिडचिडे आहे का?",
            "bool", 5, False, "symptoms.restless_irritable",
        ),
        question(
            "core.eager", "core",
            "Does the child drink eagerly or seem thirsty?",
            "क्या बच्चा बहुत तेजी से पी रहा है?",
            "मूल उत्सुकतेने पिते का?",
            "bool", 5, False, "symptoms.drinks_eagerly",
        ),
        question(
            "core.skin_pinch", "core",
            "How does the skin pinch go back?",
            "त्वचा की चुटकी वापस कैसे जाती है?",
            "त्वचेची चिमटी परत कशी जाते?",
            "choice", 5, False, "symptoms.skin_pinch",
            options=[
                {"value": "normal", "label": "Goes back immediately"},
                {"value": "slow", "label": "Goes back slowly"},
                {"value": "very_slow", "label": "Goes back very slowly, 2 seconds or more"},
            ],
        ),
        question(
            "core.malaria_test", "core",
            "Is the malaria test positive?",
            "क्या मलेरिया जांच सकारात्मक है?",
            "मलेरिया चाचणी पॉझिटिव्ह आहे का?",
            "bool", 5, False, "symptoms.malaria_test_positive",
        ),
        question(
            "core.pallor", "core",
            "Is there palmar pallor?",
            "क्या हथेली पीली है?",
            "तळहातावर फिकेपणा आहे का?",
            "bool", 5, False, "symptoms.palmar_pallor",
        ),
        question(
            "core.ear_pain", "core",
            "Does the child have ear pain?",
            "क्या बच्चे के कान में दर्द है?",
            "मुलाला कानात दुखत आहे का?",
            "bool", 4, False, "symptoms.ear_pain",
        ),
        question(
            "core.ear_discharge", "core",
            "Is there discharge from the ear?",
            "क्या कान से पानी या मवाद बह रहा है?",
            "कानातून स्त्राव होत आहे का?",
            "bool", 4, False, "symptoms.ear_discharge",
        ),
        question(
            "core.zscore", "core",
            "What is the weight-for-age Z-score?",
            "वजन-आयु Z-स्कोर कितना है?",
            "वजन-वय Z-स्कोअर किती आहे?",
            "number", 4, False, "vitals.weight_for_age_zscore",
            numeric={"unit": "Z", "min": -6, "max": 4, "decimals": 1},
        ),
        question(
            "core.ear_days", "core",
            "For how many days has the ear been discharging?",
            "कान से स्राव कितने दिन से है?",
            "कानातून स्त्राव किती दिवसांपासून आहे?",
            "number", 3, False, "symptoms.ear_discharge_days",
            numeric={"unit": "days", "min": 0, "max": 90, "decimals": 0},
        ),
        question(
            "core.weight", "core",
            "What is the weight in kilograms?",
            "वजन कितने किलो है?",
            "वजन किती किलो आहे?",
            "number", 3, False, "vitals.weight_kg",
            numeric={"unit": "kg", "min": 1, "max": 30, "decimals": 1},
        ),
        question(
            "dengue.abdominal", "dengue",
            "Is there severe abdominal pain or tenderness?",
            "क्या पेट में तेज दर्द या छूने पर दर्द है?",
            "पोटात तीव्र दुखणे किंवा दाबल्यावर दुखणे आहे का?",
            "bool", 9, True, "symptoms.severe_abdominal_pain",
        ),
        question(
            "dengue.vomiting", "dengue",
            "Is the vomiting persistent?",
            "क्या उल्टी लगातार हो रही है?",
            "उलटी सतत होत आहे का?",
            "bool", 9, True, "symptoms.persistent_vomiting",
        ),
        question(
            "dengue.bleeding", "dengue",
            "Is there bleeding from the gums or nose, or other mucosal bleeding?",
            "क्या मसूड़ों या नाक से खून आ रहा है?",
            "हिरड्या किंवा नाकातून रक्त येत आहे का?",
            "bool", 9, True, "symptoms.mucosal_bleeding",
        ),
        question(
            "dengue.fluid", "dengue",
            "Is there clinical fluid accumulation?",
            "क्या शरीर में पानी जमा दिख रहा है?",
            "शरीरात द्रव साचल्याचे लक्षण आहे का?",
            "bool", 9, True, "symptoms.clinical_fluid_accumulation",
        ),
        question(
            "dengue.restless", "dengue",
            "Is the child unusually lethargic or restless?",
            "क्या बच्चा असामान्य रूप से सुस्त या बेचैन है?",
            "मूल असामान्य सुस्त किंवा अस्वस्थ आहे का?",
            "bool", 9, True, "symptoms.dengue_restless_or_lethargic",
        ),
        question(
            "dengue.breeding", "dengue",
            "Are there water-filled containers where mosquitoes can breed near the home?",
            "क्या घर के पास मच्छरों के लिए पानी भरा पड़ा है?",
            "घराजवळ डासांच्या उत्पत्तीसाठी पाणी साचले आहे का?",
            "bool", 2, False, "symptoms.mosquito_breeding_nearby",
        ),
        question(
            "measles.rash", "measles",
            "Is there a generalised rash?",
            "क्या पूरे शरीर पर दाने हैं?",
            "अंगावर पुरळ आहे का?",
            "bool", 8, True, "symptoms.measles_rash",
        ),
        question(
            "measles.eyes", "measles",
            "Are the eyes red?",
            "क्या आंखें लाल हैं?",
            "डोळे लाल आहेत का?",
            "bool", 4, False, "symptoms.red_eyes",
        ),
        question(
            "measles.nose", "measles",
            "Does the child have a runny nose?",
            "क्या नाक बह रही है?",
            "नाक वाहत आहे का?",
            "bool", 3, False, "symptoms.runny_nose",
        ),
        question(
            "diarrhoea_cluster.many", "diarrhoea_cluster",
            "Has the child passed many watery stools today?",
            "क्या आज कई बार पतले दस्त हुए हैं?",
            "आज अनेक पातळ शौच झाले का?",
            "bool", 7, True, "symptoms.watery_stools_many",
        ),
        question(
            "aes.altered", "aes",
            "Did fever come with a sudden change in consciousness?",
            "क्या बुखार के साथ अचानक बेहोशी या व्यवहार बदला?",
            "तापाबरोबर अचानक शुद्ध हरपली किंवा वर्तन बदलले का?",
            "bool", 9, True, "symptoms.acute_encephalopathy",
        ),
    ]
    return {"questions": rows}


MANIFEST = {
    "district_id": "PCMC",
    "district_name": "Pimpri-Chinchwad",
    "state": "Maharashtra",
    "ward_count": 8,
    "pack_version": 1,
    "generated_at": "2026-10-19T00:00:00Z",
    "as_of_month": 10,
    "languages": ["mr", "hi", "en"],
    "synthetic": True,
    "note": "Sample ward boxes and a cached GPS fix. Not official boundaries. Works offline.",
    "sample_fix": {"latitude": 18.64, "longitude": 73.84, "label": "Cached fix inside sample ward W3"},
    "facilities": [
        {"id": "HFR-PCMC-W3", "name": "PCMC UPHC Ward 3", "ward_id": "W3"},
        {"id": "HFR-PCMC-W5", "name": "PCMC UPHC Ward 5", "ward_id": "W5"},
    ],
}

MODULES = {
    "modules": [
        {
            "id": "dengue",
            "condition": "dengue_like",
            "activation": {
                "min_cases_per_week": 3,
                "lookback_weeks": 4,
                "seasonal_months": [6, 7, 8, 9, 10, 11],
            },
            "red_flags": [
                "severe abdominal pain or tenderness",
                "persistent vomiting",
                "mucosal or gum bleeding",
                "lethargy or restlessness",
                "clinical fluid accumulation",
            ],
        },
        {
            "id": "measles",
            "condition": "measles_like",
            "activation": {"min_cases_per_week": 2, "lookback_weeks": 4, "seasonal_months": [1, 2, 3, 4]},
        },
        {
            "id": "diarrhoea_cluster",
            "condition": "acute_diarrhoea",
            "activation": {
                "min_cases_per_week": 8,
                "lookback_weeks": 4,
                "seasonal_months": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
            },
        },
        {
            "id": "aes",
            "condition": "aes",
            "activation": {
                "min_cases_per_week": 1,
                "lookback_weeks": 4,
                "seasonal_months": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
            },
        },
    ]
}

# Fake district priors. Swap these for NFHS-5 district fact sheets:
# - Anaemia among children: children age 6-59 months who are anaemic (<11.0 g/dl) (%)
# - Nutritional status: children under 5 who are stunted (height-for-age) (%)
# - Vaccinations: children age 12-23 months fully vaccinated (card or mother's recall) (%)
PRIORS = {
    "synthetic": True,
    "source_to_swap_in": "NFHS-5 district fact sheets. Indicators named in the comment above. PCMC is inside Pune district.",
    "districts": [
        {"district_id": "PCMC", "anaemia_children_6_59_months_pct": 62.0, "stunting_under_5_pct": 27.0, "full_immunization_12_23_months_pct": 76.0},
        {"district_id": "PUNE", "anaemia_children_6_59_months_pct": 64.0, "stunting_under_5_pct": 29.0, "full_immunization_12_23_months_pct": 74.0},
        {"district_id": "THANE", "anaemia_children_6_59_months_pct": 66.0, "stunting_under_5_pct": 31.0, "full_immunization_12_23_months_pct": 72.0},
        {"district_id": "RAIGAD", "anaemia_children_6_59_months_pct": 68.0, "stunting_under_5_pct": 33.0, "full_immunization_12_23_months_pct": 70.0},
        {"district_id": "AHMEDNAGAR", "anaemia_children_6_59_months_pct": 63.0, "stunting_under_5_pct": 34.0, "full_immunization_12_23_months_pct": 73.0},
    ],
}


def main():
    (ROOT / "manifest.json").write_text(json.dumps(MANIFEST, indent=2) + "\n")
    (ROOT / "wards.geojson").write_text(json.dumps(geojson(), indent=2) + "\n")
    (ROOT / "modules.json").write_text(json.dumps(MODULES, indent=2) + "\n")
    (ROOT / "priors.json").write_text(json.dumps(PRIORS, indent=2) + "\n")
    (ROOT / "question_bank.json").write_text(json.dumps(questions(), indent=2, ensure_ascii=False) + "\n")
    # W3 rises 1 → 5 over the last four weeks. Every other ward stays at 0.
    (ROOT / "disease_counts.csv").write_text(counts({"W3": [1, 2, 3, 5]}))
    # Version 2 of the demo: W3 falls under the threshold, W5 crosses it.
    (ROOT / "disease_counts_v2.csv").write_text(counts({"W5": [1, 2, 3, 5]}))
    print(f"wrote pack under {ROOT}")


if __name__ == "__main__":
    main()
