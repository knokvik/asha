"""Seed initial real users, facilities, and records into Supabase PostgreSQL."""
from __future__ import annotations

import asyncio
import time
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.security import hash_password
from db.session import AsyncSessionLocal
from models.db.models import FacilityDirectory, ReferralRecord, StockItem, User


USERS_SEED = [
    {
        "asha_id": "doctor",
        "name": "Dr. Alok Verma",
        "role": "PHC_MO",
        "raw_pin": "doctor123",
        "area_phc": "phc-shahpur",
        "area_block": "BLOCK_SHAHPUR",
        "area_district": "Varanasi",
        "state_code": "UP",
        "district_code": "DIST_01",
        "block_code": "BLK_01",
    },
    {
        "asha_id": "anm",
        "name": "Kavita Kumari",
        "role": "ANM",
        "raw_pin": "anm123",
        "area_subcentre": "sc-shahpur",
        "area_phc": "phc-shahpur",
        "area_block": "BLOCK_SHAHPUR",
        "area_district": "Varanasi",
        "state_code": "UP",
        "district_code": "DIST_01",
        "block_code": "BLK_01",
    },
    {
        "asha_id": "af",
        "name": "Sarita Singh",
        "role": "AF",
        "raw_pin": "af123",
        "area_block": "BLOCK_SHAHPUR",
        "area_district": "Varanasi",
        "state_code": "UP",
        "district_code": "DIST_01",
        "block_code": "BLK_01",
    },
    {
        "asha_id": "dho",
        "name": "Dr. Rajesh Pandey (CMO)",
        "role": "DISTRICT_OFFICER",
        "raw_pin": "dho123",
        "area_district": "Varanasi",
        "state_code": "UP",
        "district_code": "DIST_01",
        "block_code": "BLK_01",
    },
    {
        "asha_id": "admin",
        "name": "Priyanka Sen",
        "role": "STATE_ADMIN",
        "raw_pin": "admin123",
        "state_code": "UP",
        "district_code": "DIST_01",
        "block_code": "BLK_01",
    },
    {
        "asha_id": "ASHA-001",
        "name": "Sunita Devi",
        "role": "ASHA",
        "raw_pin": "1234",
        "area_village": "Shahpur, Ramnagar",
        "area_subcentre": "sc-shahpur",
        "area_phc": "phc-shahpur",
        "area_block": "BLOCK_SHAHPUR",
        "area_district": "Varanasi",
        "state_code": "UP",
        "district_code": "DIST_01",
        "block_code": "BLK_01",
    },
]

FACILITIES_SEED = [
    {
        "id": "phc-shahpur",
        "name": "PHC Shahpur (24x7 Emergency)",
        "facility_level": "phc",
        "district": "Varanasi",
        "block": "BLOCK_SHAHPUR",
        "village": "Shahpur",
        "latitude": 25.318,
        "longitude": 82.974,
        "contact_phone": "05426700101",
        "is_active": True,
    },
    {
        "id": "sc-shahpur",
        "name": "Sub-Centre Shahpur North",
        "facility_level": "subcentre",
        "district": "Varanasi",
        "block": "BLOCK_SHAHPUR",
        "village": "Shahpur North",
        "latitude": 25.282,
        "longitude": 83.002,
        "contact_phone": "05426700102",
        "is_active": True,
    },
    {
        "id": "chc-shivpur",
        "name": "CHC Shivpur Referral Hospital",
        "facility_level": "chc",
        "district": "Varanasi",
        "block": "BLOCK_SHAHPUR",
        "village": "Shivpur",
        "latitude": 25.355,
        "longitude": 82.980,
        "contact_phone": "05426700103",
        "is_active": True,
    },
    {
        "id": "hosp-district",
        "name": "Varanasi District Hospital",
        "facility_level": "hospital",
        "district": "Varanasi",
        "block": "BLOCK_SHAHPUR",
        "village": "Varanasi City",
        "latitude": 25.320,
        "longitude": 82.990,
        "contact_phone": "05426700100",
        "is_active": True,
    },
]

REFERRALS_SEED = [
    {
        "id": "ref-001",
        "member_id": None,
        "encounter_id": None,
        "triage_flag": "RED",
        "destination_facility_id": "phc-shahpur",
        "destination_level": "PHC",
        "transport_arranged": "yes",
        "status": "en_route",
        "referral_note_text": "High fever with severe convulsions. Urgent doctor evaluation requested.",
    },
    {
        "id": "ref-002",
        "member_id": None,
        "encounter_id": None,
        "triage_flag": "YELLOW",
        "destination_facility_id": "phc-shahpur",
        "destination_level": "PHC",
        "transport_arranged": "no",
        "status": "created",
        "referral_note_text": "Severe persistent cough >2 weeks, suspected TB screening required.",
    },
    {
        "id": "ref-003",
        "member_id": None,
        "encounter_id": None,
        "triage_flag": "GREEN",
        "destination_facility_id": "phc-shahpur",
        "destination_level": "PHC",
        "transport_arranged": "no",
        "status": "arrived",
        "referral_note_text": "Routine 3rd trimester antenatal checkup and IFA supplementation.",
    },
]


async def seed() -> None:
    async with AsyncSessionLocal() as session:
        # Seed users
        print("Seeding users...")
        for u in USERS_SEED:
            stmt = select(User).where(User.asha_id == u["asha_id"])
            existing = (await session.execute(stmt)).scalar_one_or_none()
            hashed = hash_password(u["raw_pin"])
            if existing:
                existing.hashed_pin = hashed
                existing.name = u["name"]
                existing.role = u["role"]
                existing.is_active = True
                print(f"  Updated user {u['asha_id']}")
            else:
                user = User(
                    id=str(uuid.uuid4()),
                    asha_id=u["asha_id"],
                    name=u["name"],
                    role=u["role"],
                    hashed_pin=hashed,
                    area_phc=u.get("area_phc"),
                    area_subcentre=u.get("area_subcentre"),
                    area_village=u.get("area_village"),
                    area_block=u.get("area_block"),
                    area_district=u.get("area_district"),
                    state_code=u.get("state_code"),
                    district_code=u.get("district_code"),
                    block_code=u.get("block_code"),
                    is_active=True,
                )
                session.add(user)
                print(f"  Inserted user {u['asha_id']}")

        # Seed facilities
        print("Seeding facilities...")
        for f in FACILITIES_SEED:
            stmt = select(FacilityDirectory).where(FacilityDirectory.id == f["id"])
            existing = (await session.execute(stmt)).scalar_one_or_none()
            if not existing:
                fac = FacilityDirectory(
                    id=f["id"],
                    name=f["name"],
                    facility_level=f["facility_level"],
                    district=f["district"],
                    block=f["block"],
                    village=f["village"],
                    latitude=f["latitude"],
                    longitude=f["longitude"],
                    contact_phone=f["contact_phone"],
                    is_active=True,
                    last_updated_at=int(time.time()),
                )
                session.add(fac)
                print(f"  Inserted facility {f['id']}")
            else:
                print(f"  Facility {f['id']} already exists")

        # Seed referrals
        print("Seeding referrals...")
        for r in REFERRALS_SEED:
            stmt = select(ReferralRecord).where(ReferralRecord.id == r["id"])
            existing = (await session.execute(stmt)).scalar_one_or_none()
            if not existing:
                ref = ReferralRecord(
                    id=r["id"],
                    member_id=r["member_id"],
                    encounter_id=r["encounter_id"],
                    triage_flag=r["triage_flag"],
                    destination_facility_id=r["destination_facility_id"],
                    destination_level=r["destination_level"],
                    transport_arranged=r["transport_arranged"],
                    status=r["status"],
                    referral_note_text=r["referral_note_text"],
                    created_at=int(time.time()),
                )
                session.add(ref)
                print(f"  Inserted referral {r['id']}")
            else:
                print(f"  Referral {r['id']} already exists")

        await session.commit()
        print("Seeding completed successfully!")


if __name__ == "__main__":
    asyncio.run(seed())
