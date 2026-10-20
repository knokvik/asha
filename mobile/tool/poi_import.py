#!/usr/bin/env python3
"""Merge a facility directory for the PCMC demo map.

Production inputs, when you have them:
  --hfr path.csv       ABDM Health Facility Registry export
                       columns: id,name,category,lat,lng,phone,hours,capabilities
  --overpass path.json Overpass JSON (amenity=police|townhall|pharmacy|community_centre)

With neither file, this writes 40 synthetic POIs spread across wards W1–W8.
They are marked synthetic and are not an official HFR download.

Overpass query for a later live pull (PCMC sample box):
  [out:json];
  (
    node["amenity"~"police|townhall|pharmacy|community_centre"](18.62,73.74,18.70,73.90);
    node["office"="government"](18.62,73.74,18.70,73.90);
  );
  out body;
"""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

# South row W1–W4, north row W5–W8. Same boxes as the triage pack.
WARDS = {
    "W1": (73.74, 18.62, 73.78, 18.66),
    "W2": (73.78, 18.62, 73.82, 18.66),
    "W3": (73.82, 18.62, 73.86, 18.66),
    "W4": (73.86, 18.62, 73.90, 18.66),
    "W5": (73.74, 18.66, 73.78, 18.70),
    "W6": (73.78, 18.66, 73.82, 18.70),
    "W7": (73.82, 18.66, 73.86, 18.70),
    "W8": (73.86, 18.66, 73.90, 18.70),
}

# Every directory category. The W3 lab is pinned beside the cached fix.
CATALOG = [
    ("phc", "UPHC", "08:00-16:00", ["delivery_care", "ns1_dengue_test", "oxygen", "pediatric"]),
    ("sub_centre", "Sub-centre", "09:00-15:00", ["pediatric"]),
    ("chc", "CHC", "00:00-24:00", ["delivery_care", "oxygen", "ambulance", "pediatric"]),
    ("hospital", "General hospital", "00:00-24:00", ["delivery_care", "ns1_dengue_test", "oxygen", "ambulance", "icu", "pediatric"]),
    ("dispensary", "Dispensary", "09:00-16:00", ["oxygen"]),
    ("lab", "Diagnostic lab", "09:00-17:00", ["ns1_dengue_test"]),
    ("blood_bank", "Blood bank", "09:00-17:00", []),
    ("janaushadhi", "Janaushadhi Kendra", "09:00-20:00", []),
    ("anganwadi", "Anganwadi", "09:00-13:00", []),
    ("block_office", "Block office", "10:00-17:00", []),
    ("panchayat", "Panchayat office", "10:00-17:00", []),
    ("police", "Police station", "00:00-24:00", []),
    ("ration_shop", "Ration shop", "10:00-17:00", []),
]


def _point(ward: str, slot: int) -> tuple[float, float]:
    lon0, lat0, lon1, lat1 = WARDS[ward]
    lat = lat0 + (lat1 - lat0) * (0.22 + 0.12 * (slot % 5))
    lon = lon0 + (lon1 - lon0) * (0.28 + 0.1 * (slot % 4))
    return round(lat, 5), round(lon, 5)


def demo_features() -> list[dict]:
    wards = list(WARDS)
    features = []
    for number in range(1, 41):
        category, label, hours, capabilities = CATALOG[(number - 1) % len(CATALOG)]
        ward = wards[(number - 1) % len(wards)]
        lat, lon = _point(ward, number)
        if ward == "W3" and category == "lab":
            lat, lon = 18.6412, 73.8408
        features.append(_feature(
            f"POI-{number:02d}",
            f"{label} {ward}",
            category,
            lat,
            lon,
            f"0206700{number:04d}",
            hours,
            capabilities,
            ward,
        ))
    return features


def _feature(poi_id, name, category, lat, lon, phone, hours, capabilities, ward) -> dict:
    return {
        "type": "Feature",
        "properties": {
            "id": poi_id,
            "name": name,
            "category": category,
            "phone": phone,
            "hours": hours,
            "capabilities": capabilities,
            "ward_id": ward,
            "synthetic": True,
        },
        "geometry": {"type": "Point", "coordinates": [lon, lat]},
    }


def from_hfr(path: Path) -> list[dict]:
    features = []
    with path.open(newline="") as handle:
        for row in csv.DictReader(handle):
            caps = [part.strip() for part in row.get("capabilities", "").split("|") if part.strip()]
            features.append(_feature(
                row["id"], row["name"], row["category"],
                float(row["lat"]), float(row["lng"]),
                row.get("phone", ""), row.get("hours", ""), caps, row.get("ward_id", ""),
            ))
            features[-1]["properties"]["synthetic"] = False
    return features


def from_overpass(path: Path) -> list[dict]:
    payload = json.loads(path.read_text())
    features = []
    for element in payload.get("elements", []):
        if "lat" not in element:
            continue
        tags = element.get("tags", {})
        amenity = tags.get("amenity") or tags.get("office") or "community_centre"
        category = {
            "police": "police",
            "townhall": "panchayat",
            "pharmacy": "janaushadhi",
            "community_centre": "anganwadi",
            "government": "block_office",
        }.get(amenity, "anganwadi")
        features.append(_feature(
            f"OSM-{element.get('id')}",
            tags.get("name") or category,
            category,
            float(element["lat"]),
            float(element["lon"]),
            tags.get("phone", ""),
            tags.get("opening_hours", ""),
            [],
            "",
        ))
        features[-1]["properties"]["synthetic"] = False
    return features


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--hfr", type=Path)
    parser.add_argument("--overpass", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    features = []
    if args.hfr:
        features.extend(from_hfr(args.hfr))
    if args.overpass:
        features.extend(from_overpass(args.overpass))
    if not features:
        features = demo_features()
    collection = {"type": "FeatureCollection", "features": features}
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(collection, indent=2) + "\n")
    print(f"wrote {len(features)} facilities to {args.out}")


if __name__ == "__main__":
    main()
