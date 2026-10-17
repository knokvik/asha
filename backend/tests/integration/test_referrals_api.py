"""Integration tests for referral API endpoints and non-arrival worker.

Verifies Tasks 8.4 and 8.5 (Requirements 10.4, 10.5, 10.6).
"""
from __future__ import annotations

import time
import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.models import AuditLog, Member, ReferralRecord, VisitSchedule
from services.notification_service import NotificationService
from workers.referral_worker import check_referral_arrival


@pytest.mark.asyncio
async def test_record_referral_outcome_success(
    async_client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    NotificationService.clear_dispatched()
    now_ms = int(time.time() * 1000)
    ref_id = f"ref_{uuid.uuid4()}"
    member_id = f"mem_{uuid.uuid4()}"

    # Setup patient and referral record
    member = Member(
        id=member_id,
        household_id="hh_test",
        name="Sunita Devi",
        sex="F",
        created_at=now_ms,
        updated_at=now_ms,
    )
    referral = ReferralRecord(
        id=ref_id,
        encounter_id="enc_test_1",
        member_id=member_id,
        triage_flag="RED",
        status="created",
        destination_facility_id="fac_chc_1",
        destination_level="CHC",
        created_at=now_ms - 3600000,
        updated_at=now_ms - 3600000,
        block_code="BLK_01",
    )
    db_session.add(member)
    db_session.add(referral)
    await db_session.commit()

    # Post outcome
    response = await async_client.post(
        f"/api/v1/referrals/{ref_id}/outcome",
        json={
            "outcome": "admitted",
            "receiving_facility_name": "Gopalganj Community Health Centre",
            "doctor_name": "Dr. R. K. Sharma",
            "doctor_notes": "Patient stabilized in emergency ward. Initiated IV magnesium sulfate protocol.",
            "treatment_summary": "Anti-hypertensive therapy and fetal monitoring.",
            "counter_referral_instructions": "ASHA to conduct BP monitoring twice weekly upon discharge.",
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["referral_id"] == ref_id
    assert data["status"] == "outcome_recorded"
    assert data["outcome"] == "admitted"
    assert "IV magnesium sulfate" in data["message"] or data["timeline_entry"] is not None

    # Verify DB update
    updated_ref = (
        await db_session.execute(select(ReferralRecord).where(ReferralRecord.id == ref_id))
    ).scalar_one()
    assert updated_ref.status == "outcome_recorded"
    assert updated_ref.outcome == "admitted"
    assert updated_ref.outcome_recorded_by is not None
    assert "Dr. R. K. Sharma" in (updated_ref.referral_note_text or "")
    assert "BP monitoring twice weekly" in (updated_ref.referral_note_text or "")

    # Verify AuditLog created
    audit_log = (
        await db_session.execute(
            select(AuditLog).where(
                AuditLog.record_id == ref_id,
                AuditLog.field_name == "outcome",
            )
        )
    ).scalar_one_or_none()
    assert audit_log is not None
    assert audit_log.new_value == "admitted"

    # Verify FCM notifications dispatched to ASHA and supervisor
    dispatched = NotificationService.get_dispatched()
    assert len(dispatched) >= 2
    asha_notif = next((n for n in dispatched if n.recipient_role == "ASHA"), None)
    supervisor_notif = next((n for n in dispatched if n.recipient_role == "ASHA_FACILITATOR"), None)
    assert asha_notif is not None
    assert "Sunita Devi" in asha_notif.title
    assert "Admitted" in asha_notif.body
    assert supervisor_notif is not None


@pytest.mark.asyncio
async def test_record_referral_outcome_invalid_outcome(
    async_client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    ref_id = f"ref_{uuid.uuid4()}"
    referral = ReferralRecord(
        id=ref_id,
        triage_flag="YELLOW",
        status="created",
        created_at=int(time.time() * 1000),
    )
    db_session.add(referral)
    await db_session.commit()

    response = await async_client.post(
        f"/api/v1/referrals/{ref_id}/outcome",
        json={"outcome": "invalid_status_value"},
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_record_referral_outcome_not_found(async_client: AsyncClient) -> None:
    response = await async_client.post(
        "/api/v1/referrals/non_existent_id/outcome",
        json={"outcome": "treated_discharged"},
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_update_referral_status_and_listing(
    async_client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    now_ms = int(time.time() * 1000)
    red_id = f"ref_red_{uuid.uuid4()}"
    yellow_id = f"ref_yellow_{uuid.uuid4()}"

    db_session.add(
        ReferralRecord(
            id=yellow_id,
            triage_flag="YELLOW",
            status="created",
            destination_facility_id="fac_phc_1",
            created_at=now_ms,
        )
    )
    db_session.add(
        ReferralRecord(
            id=red_id,
            triage_flag="RED",
            status="created",
            destination_facility_id="fac_phc_1",
            created_at=now_ms - 5000,
        )
    )
    await db_session.commit()

    # Update status to arrived
    stat_res = await async_client.post(
        f"/api/v1/referrals/{red_id}/status",
        json={"status": "arrived"},
    )
    assert stat_res.status_code == 200
    assert stat_res.json()["status"] == "arrived"

    # List referrals for facility: RED should be prioritized first
    list_res = await async_client.get(
        "/api/v1/referrals",
        params={"destination_facility_id": "fac_phc_1"},
    )
    assert list_res.status_code == 200
    items = list_res.json()
    assert len(items) >= 2
    # RED referral must be first in queue
    assert items[0]["triage_flag"] == "RED"


@pytest.mark.asyncio
async def test_check_referral_arrival_worker_and_endpoint(
    async_client: AsyncClient,
    db_session: AsyncSession,
) -> None:
    NotificationService.clear_dispatched()
    now_ms = int(time.time() * 1000)
    twenty_eight_hours_ago = now_ms - (28 * 3600 * 1000)
    two_hours_ago = now_ms - (2 * 3600 * 1000)

    # 1. Overdue RED referral (created 28h ago, not arrived) -> SHOULD generate task
    overdue_red_id = f"ref_overdue_{uuid.uuid4()}"
    overdue_member_id = f"mem_overdue_{uuid.uuid4()}"
    db_session.add(
        Member(
            id=overdue_member_id,
            household_id="hh_1",
            name="Pooja Kumari",
            sex="F",
            created_at=twenty_eight_hours_ago,
        )
    )
    db_session.add(
        ReferralRecord(
            id=overdue_red_id,
            encounter_id="enc_overdue_1",
            member_id=overdue_member_id,
            triage_flag="RED",
            status="created",
            created_at=twenty_eight_hours_ago,
        )
    )

    # 2. Recent RED referral (created 2h ago) -> SHOULD NOT generate task
    db_session.add(
        ReferralRecord(
            id=f"ref_recent_{uuid.uuid4()}",
            triage_flag="RED",
            status="created",
            created_at=two_hours_ago,
        )
    )

    # 3. Overdue YELLOW referral (created 28h ago) -> SHOULD NOT generate RED task
    db_session.add(
        ReferralRecord(
            id=f"ref_yellow_old_{uuid.uuid4()}",
            triage_flag="YELLOW",
            status="created",
            created_at=twenty_eight_hours_ago,
        )
    )

    # 4. Overdue RED referral already arrived -> SHOULD NOT generate task
    db_session.add(
        ReferralRecord(
            id=f"ref_arrived_old_{uuid.uuid4()}",
            triage_flag="RED",
            status="arrived",
            created_at=twenty_eight_hours_ago,
        )
    )

    await db_session.commit()

    # Trigger worker directly
    tasks = await check_referral_arrival(db_session, threshold_hours=24)
    assert len(tasks) == 1
    assert tasks[0]["referral_id"] == overdue_red_id
    assert tasks[0]["patient_name"] == "Pooja Kumari"
    assert tasks[0]["priority"] == "URGENT"

    # Verify visit schedule persisted in database
    created_task = (
        await db_session.execute(
            select(VisitSchedule).where(
                VisitSchedule.member_id == overdue_member_id,
                VisitSchedule.program_code == "RED_REFERRAL_FOLLOWUP",
            )
        )
    ).scalar_one_or_none()
    assert created_task is not None
    assert created_task.status == "urgent_overdue"
    assert "Pooja Kumari" in (created_task.visit_type or "")

    # Verify notification dispatched to ASHA and AF
    dispatched = NotificationService.get_dispatched()
    assert any("RED Referral Non-Arrival" in n.title for n in dispatched)
    assert any("ESCALATION" in n.title for n in dispatched)

    # Verify idempotency: running again should not generate duplicates
    second_run = await check_referral_arrival(db_session, threshold_hours=24)
    assert len(second_run) == 0

    # Verify API trigger endpoint responds
    api_resp = await async_client.post("/api/v1/referrals/check-non-arrival?threshold_hours=24")
    assert api_resp.status_code == 200
    assert api_resp.json()["status"] == "completed"
