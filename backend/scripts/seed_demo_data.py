"""Opt-in local/integration fixture for the real auth and sync flow.

This command is deliberately never called by Render startup. It creates two
clearly labelled test accounts, one ASHA mobile account and one PHC web
account, plus one household, member, and due task assigned to the ASHA.

Run only against a disposable/test database:

    python -m scripts.seed_demo_data --apply

The default credentials are for local integration testing only and must not be
used in production.
"""
from __future__ import annotations

import argparse
import asyncio
import uuid
from datetime import datetime, timezone

from sqlalchemy import select

from core.security import hash_password
from db.session import AsyncSessionLocal
from models.db.models import Household, Member, User, VisitSchedule

ASHA_ID = "ASHA_TEST_MOBILE"
PHC_ID = "PHC_TEST_WEB"
ASHA_PIN = "2468"
PHC_PIN = "1357"


def _id() -> str:
    return str(uuid.uuid4())


async def seed() -> None:
    async with AsyncSessionLocal() as db:
        asha = await db.scalar(select(User).where(User.asha_id == ASHA_ID))
        if asha is None:
            asha = User(
                id=_id(),
                asha_id=ASHA_ID,
                name="Test ASHA Mobile",
                role="ASHA",
                area_village="Test Village",
                area_subcentre="TEST_SUBCENTRE",
                area_phc="TEST_PHC",
                area_block="TEST_BLOCK",
                area_district="TEST_DISTRICT",
                area_state="TEST_STATE",
                state_code="TEST",
                district_code="TEST_DISTRICT",
                block_code="TEST_BLOCK",
                hashed_pin=hash_password(ASHA_PIN),
                is_active=True,
            )
            db.add(asha)

        phc = await db.scalar(select(User).where(User.asha_id == PHC_ID))
        if phc is None:
            phc = User(
                id=_id(),
                asha_id=PHC_ID,
                name="Test PHC Officer",
                role="PHC_MO",
                area_phc="TEST_PHC",
                area_block="TEST_BLOCK",
                area_district="TEST_DISTRICT",
                area_state="TEST_STATE",
                state_code="TEST",
                district_code="TEST_DISTRICT",
                block_code="TEST_BLOCK",
                hashed_pin=hash_password(PHC_PIN),
                is_active=True,
            )
            db.add(phc)

        await db.flush()

        household_id = "test-household-001"
        household = await db.get(Household, household_id)
        if household is None:
            db.add(
                Household(
                    id=household_id,
                    village="Test Village",
                    hamlet="Test Hamlet",
                    head_name="Test Family",
                    member_count=1,
                    created_at=int(datetime.now(timezone.utc).timestamp() * 1000),
                    updated_at=int(datetime.now(timezone.utc).timestamp() * 1000),
                    created_by=asha.id,
                    worker_id=asha.id,
                    state_code=asha.state_code,
                    district_code=asha.district_code,
                    block_code=asha.block_code,
                    sync_status="synced",
                )
            )

        member_id = "test-member-001"
        member = await db.get(Member, member_id)
        if member is None:
            db.add(
                Member(
                    id=member_id,
                    household_id=household_id,
                    name="Test Beneficiary",
                    sex="F",
                    lifecycle_status="active",
                    consent_status="granted",
                    created_by=asha.id,
                    worker_id=asha.id,
                    state_code=asha.state_code,
                    district_code=asha.district_code,
                    block_code=asha.block_code,
                    sync_status="synced",
                )
            )

        schedule_id = "test-visit-001"
        if await db.get(VisitSchedule, schedule_id) is None:
            db.add(
                VisitSchedule(
                    id=schedule_id,
                    member_id=member_id,
                    program_code="ANC",
                    visit_type="ANC follow-up",
                    due_date=int(datetime.now(timezone.utc).timestamp() * 1000),
                    status="pending",
                    block_code=asha.block_code,
                )
            )

        await db.commit()
        print(f"Seeded test accounts: {ASHA_ID} and {PHC_ID}")
        print(f"Test PINs: ASHA={ASHA_PIN}, PHC={PHC_PIN}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    if not args.apply:
        print("Dry run. Re-run with --apply against a disposable/test database.")
        return
    asyncio.run(seed())


if __name__ == "__main__":
    main()
