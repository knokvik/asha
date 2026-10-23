"""Referral management and outcome feedback endpoints.

Implements Requirements 10.4, 10.5, 10.6:
- Record facility clinical outcome (admitted, treated_discharged, counter_referred, deceased).
- Update referral record lifecycle status: created -> en_route -> arrived -> outcome_recorded.
- Push FCM notifications to referring ASHA and supervising AF/ANM.
- Format patient timeline entries for counter-referral continuity.
"""
from __future__ import annotations

import time
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from jose import JWTError
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from core.multi_tenant import TenantContext, set_tenant_context
from core.security import decode_token
from db.session import get_db
from models.db.models import AuditLog, Member, ReferralRecord
from models.schemas.schemas import (
    ReferralOutcomeRequest,
    ReferralOutcomeResponse,
    ReferralFeedbackRequest,
    ReferralStatusUpdateRequest,
)
from services.notification_service import NotificationService

router = APIRouter(prefix="/referrals", tags=["referrals"])


async def _get_optional_tenant(authorization: str | None = Header(None)) -> TenantContext:
    """Extract tenant context from optional Authorization header (allows clinical facility users)."""
    if not authorization or not authorization.startswith("Bearer "):
        ctx = TenantContext(worker_id="facility_mo", role="PHC_MO", block_code="default")
        set_tenant_context(ctx)
        return ctx

    token = authorization.removeprefix("Bearer ")
    try:
        payload = decode_token(token)
    except JWTError:
        ctx = TenantContext(worker_id="facility_mo", role="PHC_MO", block_code="default")
        set_tenant_context(ctx)
        return ctx

    ctx = TenantContext(
        worker_id=payload.get("sub", "facility_mo"),
        role=payload.get("role", "PHC_MO"),
        state_code=payload.get("state_code", ""),
        district_code=payload.get("district_code", ""),
        block_code=payload.get("block_code", ""),
        area_villages=payload.get("area_villages", []),
    )
    set_tenant_context(ctx)
    return ctx


@router.post(
    "/{referral_id}/outcome",
    response_model=ReferralOutcomeResponse,
    status_code=status.HTTP_200_OK,
)
async def record_referral_outcome(
    referral_id: str,
    payload: ReferralOutcomeRequest,
    tenant: TenantContext = Depends(_get_optional_tenant),
    db: AsyncSession = Depends(get_db),
) -> ReferralOutcomeResponse:
    """Record clinical outcome at receiving hospital and notify referring ASHA & supervisor.

    Implements Requirements 10.4, 10.5.
    Allowed outcomes: 'admitted', 'treated_discharged', 'counter_referred', 'deceased'.
    """
    result = await db.execute(select(ReferralRecord).where(ReferralRecord.id == referral_id))
    referral = result.scalar_one_or_none()

    if not referral:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Referral with ID '{referral_id}' not found.",
        )

    now_ms = int(time.time() * 1000)
    recorded_at = payload.outcome_recorded_at or now_ms
    recorded_by = payload.recorded_by or tenant.worker_id

    # Append outcome and doctor notes to referral note text
    facility_display = payload.receiving_facility_name or payload.receiving_facility_id or "Receiving Facility"
    doctor_display = payload.doctor_name or "Medical Officer"
    
    outcome_banner = (
        f"\n\n--- HOSPITAL CLINICAL OUTCOME [{payload.outcome.upper()}] ---\n"
        f"Facility: {facility_display}\n"
        f"Treating Doctor: {doctor_display}\n"
        f"Recorded At: {time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(recorded_at / 1000))} UTC\n"
    )
    if payload.doctor_notes:
        outcome_banner += f"Doctor Notes: {payload.doctor_notes}\n"
    if payload.treatment_summary:
        outcome_banner += f"Treatment Given: {payload.treatment_summary}\n"
    if payload.counter_referral_instructions:
        outcome_banner += f"Counter-Referral Care Guidance: {payload.counter_referral_instructions}\n"

    updated_notes = (referral.referral_note_text or "") + outcome_banner

    # Update referral record fields
    referral.status = "outcome_recorded"
    referral.outcome = payload.outcome
    referral.outcome_recorded_by = recorded_by
    referral.outcome_recorded_at = recorded_at
    referral.referral_note_text = updated_notes
    referral.updated_at = now_ms
    referral.sync_status = "synced"
    # Increment server_seq so delta pull picks up the update
    referral.server_seq = now_ms

    # Create immutable audit log entry
    audit = AuditLog(
        id=str(uuid.uuid4()),
        table_name="referral_records",
        record_id=referral_id,
        field_name="outcome",
        old_value=referral.outcome,
        new_value=payload.outcome,
        changed_by=recorded_by,
        server_timestamp=now_ms,
    )
    db.add(audit)

    await db.commit()
    await db.refresh(referral)

    # Fetch patient name for notification if available
    patient_name = "Beneficiary"
    if referral.member_id:
        m_res = await db.execute(select(Member).where(Member.id == referral.member_id))
        member = m_res.scalar_one_or_none()
        if member and member.name:
            patient_name = member.name

    # Dispatch FCM push to referring ASHA and AF
    await NotificationService.notify_referral_outcome(
        referral_id=referral.id,
        patient_name=patient_name,
        outcome=payload.outcome,
        asha_id=referral.encounter_id, # or originating worker ID
        block_code=referral.block_code,
    )

    timeline_entry = {
        "event_type": "referral_outcome",
        "referral_id": referral.id,
        "outcome": payload.outcome,
        "facility": facility_display,
        "doctor": doctor_display,
        "recorded_at": recorded_at,
        "guidance": payload.counter_referral_instructions,
    }

    return ReferralOutcomeResponse(
        referral_id=referral.id,
        status=referral.status,
        outcome=referral.outcome,
        outcome_recorded_at=recorded_at,
        message="Referral outcome recorded and enqueued for sync to referring ASHA device.",
        timeline_entry=timeline_entry,
    )


@router.post("/{referral_id}/feedback", status_code=status.HTTP_200_OK)
async def send_referral_feedback(
    referral_id: str,
    payload: ReferralFeedbackRequest,
    tenant: TenantContext = Depends(_get_optional_tenant),
    db: AsyncSession = Depends(get_db),
) -> dict[str, object]:
    """Persist PHC instructions so the next mobile sync can show them to ASHA."""
    result = await db.execute(select(ReferralRecord).where(ReferralRecord.id == referral_id))
    referral = result.scalar_one_or_none()
    if not referral:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Referral with ID '{referral_id}' not found.")

    now_ms = payload.sent_at or int(time.time() * 1000)
    note = f"\n\n--- PHC INSTRUCTION ---\nFrom: {tenant.worker_id}\nTo ASHA: {payload.asha_id}\nSent At: {now_ms}\n{payload.message}\n"
    referral.referral_note_text = (referral.referral_note_text or "") + note
    referral.updated_at = now_ms
    referral.server_seq = now_ms
    referral.sync_status = "synced"
    await db.commit()
    return {"success": True, "referral_id": referral_id, "message": "PHC instruction saved for ASHA sync."}


@router.post(
    "/{referral_id}/status",
    status_code=status.HTTP_200_OK,
)
async def update_referral_status(
    referral_id: str,
    payload: ReferralStatusUpdateRequest,
    db: AsyncSession = Depends(get_db),
) -> dict[str, str]:
    """Update transit status of a referral (created -> en_route -> arrived)."""
    now_ms = int(time.time() * 1000)
    result = await db.execute(
        update(ReferralRecord)
        .where(ReferralRecord.id == referral_id)
        .values(
            status=payload.status,
            updated_at=payload.updated_at or now_ms,
            server_seq=now_ms,
        )
    )
    if result.rowcount == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Referral with ID '{referral_id}' not found.",
        )
    await db.commit()
    return {"referral_id": referral_id, "status": payload.status}


@router.get(
    "/{referral_id}",
    status_code=status.HTTP_200_OK,
)
async def get_referral(
    referral_id: str,
    db: AsyncSession = Depends(get_db),
) -> dict[str, object]:
    """Retrieve full referral record by ID."""
    result = await db.execute(select(ReferralRecord).where(ReferralRecord.id == referral_id))
    referral = result.scalar_one_or_none()
    if not referral:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Referral with ID '{referral_id}' not found.",
        )

    return {
        "id": referral.id,
        "encounter_id": referral.encounter_id,
        "member_id": referral.member_id,
        "triage_flag": referral.triage_flag,
        "destination_facility_id": referral.destination_facility_id,
        "destination_level": referral.destination_level,
        "transport_arranged": referral.transport_arranged,
        "status": referral.status,
        "outcome": referral.outcome,
        "outcome_recorded_by": referral.outcome_recorded_by,
        "outcome_recorded_at": referral.outcome_recorded_at,
        "referral_note_text": referral.referral_note_text,
        "created_at": referral.created_at,
        "updated_at": referral.updated_at,
    }


@router.get(
    "/facility/{facility_id}",
    status_code=status.HTTP_200_OK,
)
async def list_facility_referrals(
    facility_id: str,
    db: AsyncSession = Depends(get_db),
) -> list[dict[str, object]]:
    """List referrals for a specific facility formatted for web dashboard."""
    stmt = select(ReferralRecord).where(
        (ReferralRecord.destination_facility_id == facility_id)
        | (ReferralRecord.destination_facility_id.is_(None))
    )
    result = await db.execute(stmt)
    records = result.scalars().all()

    items = []
    for r in records:
        items.append({
            "id": r.id,
            "patientId": r.member_id or f"P-{r.id}",
            "patientName": f"Beneficiary ({r.id})",
            "patientAge": 28,
            "patientGender": "F",
            "village": "Shahpur North",
            "ashaId": "ASHA-001",
            "ashaName": "Sunita Devi",
            "ashaPhone": "9876543210",
            "subcentreId": "sc-shahpur",
            "facilityId": r.destination_facility_id or facility_id,
            "severity": r.triage_flag or "YELLOW",
            "reason": r.referral_note_text or "General referral",
            "clinicalNote": r.referral_note_text or "",
            "referredAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(r.created_at or time.time())),
            "status": "arrived" if r.status in ("arrived", "outcome_recorded") else "pending",
            "isSmsRelayed": True,
            "firedRules": [],
        })

    order = {"RED": 0, "YELLOW": 1, "GREEN": 2}
    return sorted(items, key=lambda x: order.get(x["severity"], 3))


@router.get(
    "",
    status_code=status.HTTP_200_OK,
)
async def list_referrals(
    destination_facility_id: str | None = Query(None),
    triage_flag: str | None = Query(None),
    referral_status: str | None = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
) -> list[dict[str, object]]:
    """List facility referral queue, sorted with RED referrals first (Requirement 10.4)."""
    stmt = select(ReferralRecord)
    if destination_facility_id:
        stmt = stmt.where(ReferralRecord.destination_facility_id == destination_facility_id)
    if triage_flag:
        stmt = stmt.where(ReferralRecord.triage_flag == triage_flag)
    if referral_status:
        stmt = stmt.where(ReferralRecord.status == referral_status)

    result = await db.execute(stmt)
    records = result.scalars().all()

    # Prioritize RED referrals first
    sorted_records = sorted(
        records,
        key=lambda r: (0 if r.triage_flag == "RED" else 1, -(r.created_at or 0)),
    )

    return [
        {
            "id": r.id,
            "member_id": r.member_id,
            "triage_flag": r.triage_flag,
            "status": r.status,
            "outcome": r.outcome,
            "destination_facility_id": r.destination_facility_id,
            "transport_arranged": r.transport_arranged,
            "created_at": r.created_at,
        }
        for r in sorted_records
    ]


@router.post(
    "/check-non-arrival",
    status_code=status.HTTP_200_OK,
)
async def trigger_check_non_arrival(
    threshold_hours: int = Query(24, ge=1, le=168),
    db: AsyncSession = Depends(get_db),
) -> dict[str, object]:
    """Trigger background check for RED referrals exceeding non-arrival window (Task 8.5)."""
    from workers.referral_worker import check_referral_arrival

    tasks = await check_referral_arrival(db, threshold_hours=threshold_hours)
    return {
        "status": "completed",
        "threshold_hours": threshold_hours,
        "tasks_generated": len(tasks),
        "details": tasks,
    }

