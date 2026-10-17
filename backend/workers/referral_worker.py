"""Referral worker for background checks and non-arrival follow-up generation.

Implements Requirement 10.6 and Task 8.5:
- Periodic job `check_referral_arrival`: runs every 30 min.
- Identifies RED referrals with no arrival outcome past a configurable window (default 24 hours).
- Automatically generates an urgent visit schedule / follow-up task for the referring ASHA.
- Dispatches emergency escalation alert to the ASHA Facilitator (AF).
"""
from __future__ import annotations

import logging
import time
import uuid
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.models import Member, ReferralRecord, VisitSchedule
from services.notification_service import NotificationService

logger = logging.getLogger(__name__)


async def check_referral_arrival(
    db: AsyncSession,
    threshold_hours: int = 24,
) -> list[dict[str, Any]]:
    """Scan for RED referrals exceeding non-arrival threshold and generate urgent follow-up tasks.

    Requirement 10.6:
    For RED referrals with status != 'arrived' and status != 'outcome_recorded'
    after threshold_hours (default 24h), create overdue follow-up task for ASHA and alert AF.
    """
    now_ms = int(time.time() * 1000)
    cutoff_time_ms = now_ms - (threshold_hours * 3600 * 1000)

    # 1. Query matching RED referrals
    query = (
        select(ReferralRecord)
        .where(ReferralRecord.triage_flag == "RED")
        .where(ReferralRecord.status.not_in(["arrived", "outcome_recorded"]))
        .where(ReferralRecord.created_at <= cutoff_time_ms)
    )
    result = await db.execute(query)
    overdue_referrals = result.scalars().all()

    generated_tasks: list[dict[str, Any]] = []

    for ref in overdue_referrals:
        # Check if an active follow-up task for this referral already exists
        existing_task_query = (
            select(VisitSchedule)
            .where(VisitSchedule.member_id == ref.member_id)
            .where(VisitSchedule.program_code == "RED_REFERRAL_FOLLOWUP")
            .where(VisitSchedule.completed_encounter_id == ref.encounter_id)
        )
        existing_result = await db.execute(existing_task_query)
        if existing_result.scalar_one_or_none() is not None:
            continue

        # Fetch patient demographic name
        patient_name = "Beneficiary"
        if ref.member_id:
            m_res = await db.execute(select(Member).where(Member.id == ref.member_id))
            member = m_res.scalar_one_or_none()
            if member and member.name:
                patient_name = member.name

        task_id = str(uuid.uuid4())
        visit_title = f"RED referral non-arrival follow-up: {patient_name}"

        # 2. Generate urgent visit task for referring ASHA
        follow_up_task = VisitSchedule(
            id=task_id,
            member_id=ref.member_id or "unknown_member",
            program_code="RED_REFERRAL_FOLLOWUP",
            visit_type=visit_title,
            due_date=now_ms,
            due_window_start=now_ms,
            due_window_end=now_ms + (24 * 3600 * 1000),
            status="urgent_overdue",
            completed_encounter_id=ref.encounter_id,
            created_at=now_ms,
            rescheduled_count=0,
            block_code=ref.block_code,
            server_seq=now_ms,
        )
        db.add(follow_up_task)

        # 3. Send urgent alert to referring ASHA and escalate to AF
        asha_id = ref.encounter_id or "assigned_asha"
        await NotificationService.notify_non_arrival_overdue(
            referral_id=ref.id,
            patient_name=patient_name,
            asha_id=asha_id,
            hours_elapsed=threshold_hours,
        )

        generated_tasks.append(
            {
                "task_id": task_id,
                "referral_id": ref.id,
                "member_id": ref.member_id,
                "patient_name": patient_name,
                "visit_type": visit_title,
                "priority": "URGENT",
                "due_date": now_ms,
            }
        )

    if generated_tasks:
        await db.commit()
        logger.info(
            "check_referral_arrival: generated %d urgent follow-up tasks for overdue RED referrals",
            len(generated_tasks),
        )

    return generated_tasks
