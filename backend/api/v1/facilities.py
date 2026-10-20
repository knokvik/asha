"""Dummy all-India facility points for map testing.

These are not ABDM, HFR, or NHRR records. Names and coordinates are synthetic
so the phone and the dashboard can draw PHCs, health centres, and other
resources without a government login.
"""
from __future__ import annotations

from fastapi import APIRouter

router = APIRouter(tags=["facilities"])

DUMMY_FACILITIES: list[dict] = [
    {"id": "PHC-PCMC-01", "name": "UPHC Pimple Saudagar", "kind": "phc", "state": "Maharashtra", "district": "Pune", "lat": 18.597, "lon": 73.789, "phone": "02067001001"},
    {"id": "CHC-PCMC-02", "name": "CHC Chinchwad", "kind": "chc", "state": "Maharashtra", "district": "Pune", "lat": 18.629, "lon": 73.800, "phone": "02067001002"},
    {"id": "SC-PCMC-03", "name": "Sub-centre Wakad", "kind": "subcentre", "state": "Maharashtra", "district": "Pune", "lat": 18.598, "lon": 73.763, "phone": "02067001003"},
    {"id": "HOSP-PCMC-04", "name": "Yashwantrao Chavan Memorial (demo)", "kind": "hospital", "state": "Maharashtra", "district": "Pune", "lat": 18.651, "lon": 73.813, "phone": "02067001004"},
    {"id": "AWC-PCMC-05", "name": "Anganwadi Kalewadi", "kind": "anganwadi", "state": "Maharashtra", "district": "Pune", "lat": 18.616, "lon": 73.790, "phone": "02067001005"},
    {"id": "BB-PCMC-06", "name": "Blood bank Bhosari (demo)", "kind": "blood_bank", "state": "Maharashtra", "district": "Pune", "lat": 18.621, "lon": 73.847, "phone": "02067001006"},
    {"id": "JAN-PCMC-07", "name": "Janaushadhi Kendra Nigdi", "kind": "janaushadhi", "state": "Maharashtra", "district": "Pune", "lat": 18.667, "lon": 73.771, "phone": "02067001007"},
    {"id": "PHC-VAR-01", "name": "PHC Ramnagar (demo)", "kind": "phc", "state": "Uttar Pradesh", "district": "Varanasi", "lat": 25.318, "lon": 82.974, "phone": "05426700101"},
    {"id": "SC-VAR-02", "name": "Sub-centre Lanka", "kind": "subcentre", "state": "Uttar Pradesh", "district": "Varanasi", "lat": 25.282, "lon": 83.002, "phone": "05426700102"},
    {"id": "CHC-VAR-03", "name": "CHC Shivpur", "kind": "chc", "state": "Uttar Pradesh", "district": "Varanasi", "lat": 25.355, "lon": 82.980, "phone": "05426700103"},
    {"id": "AWC-VAR-04", "name": "Anganwadi Sigra", "kind": "anganwadi", "state": "Uttar Pradesh", "district": "Varanasi", "lat": 25.317, "lon": 82.991, "phone": "05426700104"},
    {"id": "HOSP-DEL-01", "name": "District hospital demo, Delhi", "kind": "hospital", "state": "Delhi", "district": "New Delhi", "lat": 28.614, "lon": 77.209, "phone": "01126700101"},
    {"id": "PHC-JAI-01", "name": "PHC Sanganer (demo)", "kind": "phc", "state": "Rajasthan", "district": "Jaipur", "lat": 26.812, "lon": 75.789, "phone": "01412670011"},
    {"id": "PHC-HYD-01", "name": "UPHC Kukatpally (demo)", "kind": "phc", "state": "Telangana", "district": "Hyderabad", "lat": 17.494, "lon": 78.399, "phone": "04026700101"},
    {"id": "PHC-CHE-01", "name": "UPHC T Nagar (demo)", "kind": "phc", "state": "Tamil Nadu", "district": "Chennai", "lat": 13.041, "lon": 80.234, "phone": "04426700101"},
    {"id": "PHC-KOL-01", "name": "UPHC Salt Lake (demo)", "kind": "phc", "state": "West Bengal", "district": "Kolkata", "lat": 22.586, "lon": 88.417, "phone": "03326700101"},
    {"id": "GOV-PCMC-01", "name": "Pimpri police station (demo)", "kind": "government", "state": "Maharashtra", "district": "Pune", "lat": 18.622, "lon": 73.813, "phone": "02067001901"},
]


@router.get("/facilities/dummy")
async def dummy_facilities() -> dict:
    return {
        "source": "synthetic",
        "note": "Fake points for testing. Not an HFR or ABDM export.",
        "facilities": DUMMY_FACILITIES,
    }
