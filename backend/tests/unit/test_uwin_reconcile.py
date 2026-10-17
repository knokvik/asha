"""Unit tests for U-WIN Immunization Reconciliation worker (Requirement 16.5, Task 10.1)."""
from __future__ import annotations

import time
import uuid
import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.models import ClinicalEncounter, ClinicalObservation, Household, Member, VisitSchedule
from workers.uwin_reconcile import reconcile_uwin_records


@pytest.mark.asyncio
async def test_uwin_reconcile_imports_new_dose_and_completes_schedule(db_session: AsyncSession):
    now = int(time.time() * 1000)
    member_id = f"m_{uuid.uuid4().hex[:8]}"
    hh_id = f"hh_{uuid.uuid4().hex[:8]}"

    # Seed household & member
    hh = Household(id=hh_id, village="Rampur", created_at=now, updated_at=now)
    db_session.add(hh)

    member = Member(
        id=member_id,
        household_id=hh_id,
        name="Aarav Kumar",
        sex="M",
        phone="9876543210",
        created_at=now,
        updated_at=now,
        created_by="asha_01",
    )
    db_session.add(member)

    # Seed pending VisitSchedule for BCG
    sched_id = f"sched_bcg_{uuid.uuid4().hex[:8]}"
    schedule = VisitSchedule(
        id=sched_id,
        member_id=member_id,
        program_code="immunization",
        visit_type="BCG: BCG Vaccine",
        due_date=now,
        status="pending",
        created_at=now,
    )
    db_session.add(schedule)
    await db_session.commit()

    # Reconcile incoming U-WIN record
    uwin_records = [
        {
            "member_id": member_id,
            "vaccine_code": "BCG",
            "administered_date_ms": now,
            "batch_number": "UWIN-BCG-99",
            "facility_name": "Rampur PHC",
            "vaccinator_name": "ANM Sunita",
        }
    ]

    stats = await reconcile_uwin_records(db_session, uwin_records)

    assert stats["total_records"] == 1
    assert stats["new_doses_imported"] == 1
    assert stats["visit_schedules_completed"] == 1
    assert stats["already_recorded"] == 0

    # Verify VisitSchedule is completed
    await db_session.refresh(schedule)
    assert schedule.status == "completed"
    assert schedule.completed_encounter_id is not None


@pytest.mark.asyncio
async def test_uwin_reconcile_avoids_duplicate_entry(db_session: AsyncSession):
    now = int(time.time() * 1000)
    member_id = f"m_{uuid.uuid4().hex[:8]}"
    hh_id = f"hh_{uuid.uuid4().hex[:8]}"

    hh = Household(id=hh_id, village="Rampur", created_at=now, updated_at=now)
    db_session.add(hh)
    member = Member(
        id=member_id,
        household_id=hh_id,
        name="Kavya Singh",
        sex="F",
        created_at=now,
        updated_at=now,
        created_by="asha_01",
    )
    db_session.add(member)

    # Pre-record Penta-1 encounter and observation
    enc_id = f"enc_{uuid.uuid4().hex[:8]}"
    enc = ClinicalEncounter(
        id=enc_id,
        member_id=member_id,
        encounter_type="IMMUNIZATION_DOSE",
        program_code="immunization",
        encounter_date=now,
        asha_id="asha_01",
        status="completed",
        created_at=now,
        updated_at=now,
    )
    db_session.add(enc)

    obs = ClinicalObservation(
        id=str(uuid.uuid4()),
        encounter_id=enc_id,
        observation_code="VACCINE_CODE",
        value_text="PENTA_1",
        observed_at=now,
    )
    db_session.add(obs)
    await db_session.commit()

    # Reconcile incoming duplicate U-WIN record
    uwin_records = [
        {
            "member_id": member_id,
            "vaccine_code": "PENTA_1",
            "administered_date_ms": now,
        }
    ]

    stats = await reconcile_uwin_records(db_session, uwin_records)

    assert stats["already_recorded"] == 1
    assert stats["new_doses_imported"] == 0


@pytest.mark.asyncio
async def test_uwin_reconcile_handles_unmatched_beneficiary(db_session: AsyncSession):
    uwin_records = [
        {
            "member_id": "non_existent_member_12345",
            "vaccine_code": "OPV_1",
        }
    ]

    stats = await reconcile_uwin_records(db_session, uwin_records)

    assert stats["unmatched_beneficiaries"] == 1
    assert stats["new_doses_imported"] == 0
