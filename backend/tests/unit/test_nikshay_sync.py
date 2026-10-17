"""Unit tests for Ni-kshay TB Reconciliation worker (Requirement 20.6, Task 10.4)."""
from __future__ import annotations

import time
import uuid
import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.models import ClinicalEncounter, Household, Member, VisitSchedule
from workers.nikshay_sync import reconcile_nikshay_records


@pytest.mark.asyncio
async def test_nikshay_reconcile_imports_tb_treatment_and_completes_schedule(db_session: AsyncSession):
    now = int(time.time() * 1000)
    member_id = f"m_{uuid.uuid4().hex[:8]}"
    hh_id = f"hh_{uuid.uuid4().hex[:8]}"

    # Seed household & member
    hh = Household(id=hh_id, village="Rampur", created_at=now, updated_at=now)
    db_session.add(hh)

    member = Member(
        id=member_id,
        household_id=hh_id,
        name="Sunil Sharma",
        sex="M",
        phone="9876541234",
        created_at=now,
        updated_at=now,
        created_by="asha_01",
    )
    db_session.add(member)

    # Seed pending VisitSchedule for TB Sputum / Initiation
    sched_id = f"sched_tb_{uuid.uuid4().hex[:8]}"
    schedule = VisitSchedule(
        id=sched_id,
        member_id=member_id,
        program_code="tb",
        visit_type="Sputum Sample Collection & Truenat/NAAT Follow-Up",
        due_date=now,
        status="pending",
        created_at=now,
    )
    db_session.add(schedule)
    await db_session.commit()

    # Reconcile incoming Ni-kshay record
    nikshay_records = [
        {
            "member_id": member_id,
            "nikshay_id": "NK-2026-987654",
            "regimen": "DS-TB Daily 4-Drug FDC (HRZE)",
            "treatment_start_date_ms": now,
            "nikshay_poshan_status": "APPROVED",
        }
    ]

    stats = await reconcile_nikshay_records(db_session, nikshay_records)

    assert stats["total_records"] == 1
    assert stats["new_treatments_reconciled"] == 1
    assert stats["visit_schedules_completed"] == 1
    assert stats["already_recorded"] == 0

    # Verify VisitSchedule is completed
    await db_session.refresh(schedule)
    assert schedule.status == "completed"
    assert schedule.completed_encounter_id is not None


@pytest.mark.asyncio
async def test_nikshay_reconcile_avoids_duplicate_entry(db_session: AsyncSession):
    now = int(time.time() * 1000)
    member_id = f"m_{uuid.uuid4().hex[:8]}"
    hh_id = f"hh_{uuid.uuid4().hex[:8]}"

    hh = Household(id=hh_id, village="Rampur", created_at=now, updated_at=now)
    db_session.add(hh)
    member = Member(
        id=member_id,
        household_id=hh_id,
        name="Rekha Devi",
        sex="F",
        created_at=now,
        updated_at=now,
        created_by="asha_01",
    )
    db_session.add(member)

    # Pre-record TB_TREATMENT_REGISTRATION encounter
    enc_id = f"enc_tb_{uuid.uuid4().hex[:8]}"
    enc = ClinicalEncounter(
        id=enc_id,
        member_id=member_id,
        encounter_type="TB_TREATMENT_REGISTRATION",
        program_code="tb",
        encounter_date=now,
        asha_id="asha_01",
        status="completed",
        created_at=now,
        updated_at=now,
    )
    db_session.add(enc)
    await db_session.commit()

    # Incoming Ni-kshay record for already registered patient
    nikshay_records = [
        {
            "member_id": member_id,
            "nikshay_id": "NK-2026-112233",
            "regimen": "DS-TB Daily FDC",
        }
    ]

    stats = await reconcile_nikshay_records(db_session, nikshay_records)

    assert stats["already_recorded"] == 1
    assert stats["new_treatments_reconciled"] == 0


@pytest.mark.asyncio
async def test_nikshay_reconcile_handles_unmatched_beneficiary(db_session: AsyncSession):
    nikshay_records = [
        {
            "member_id": "non_existent_member_tb_999",
            "nikshay_id": "NK-UNKNOWN",
        }
    ]

    stats = await reconcile_nikshay_records(db_session, nikshay_records)

    assert stats["unmatched_beneficiaries"] == 1
    assert stats["new_treatments_reconciled"] == 0
