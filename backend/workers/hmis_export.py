"""HMIS (Health Management Information System) Indicator Computation & Export Worker.

Implements Requirement 35 (35.4, 35.6, 35.7) and Task 13.6:
- Computes 45+ monthly HMIS indicators from event/encounter data on 1st of month.
- Prepares draft indicators for ANM review and approval prior to submission.
- Exports state-specific standard template (CSV/Excel compatible).
- Employs state-level mapping configuration without hardcoded indicators.
- Logs outbound submissions to OutboundSharingLog for DPDP compliance.
- Logs calculation and export incidents to IntegrationIncident table.
"""
from __future__ import annotations

import csv
import io
import json
import logging
from pathlib import Path
import time
import uuid
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.models import (
    ClinicalEncounter,
    ClinicalObservation,
    IntegrationIncident,
    Member,
    OutboundSharingLog,
)

logger = logging.getLogger(__name__)

MAPPINGS_DIR = Path(__file__).resolve().parent.parent / "config" / "mappings"


def _now_ms() -> int:
    return int(time.time() * 1000)


def load_hmis_mapping(state_code: str = "default") -> dict[str, Any]:
    """Loads HMIS indicator mapping configuration, supporting state-level overrides."""
    state_file = MAPPINGS_DIR / f"hmis_mapping_{state_code.lower()}.json"
    default_file = MAPPINGS_DIR / "hmis_mapping.json"

    file_to_load = state_file if state_file.exists() else default_file
    if file_to_load.exists():
        with open(file_to_load, encoding="utf-8") as f:
            return json.load(f)

    return {"system": "HMIS", "indicators": {}}


def _parse_period_range_ms(period: str) -> tuple[int, int]:
    """Parses a YYYY-MM period into [start_ms, end_ms] timestamps.

    Defaults to the entire calendar month in UTC.
    """
    try:
        parts = period.strip().split("-")
        year = int(parts[0])
        month = int(parts[1])

        import calendar
        from datetime import datetime, timezone

        _, last_day = calendar.monthrange(year, month)
        start_dt = datetime(year, month, 1, 0, 0, 0, tzinfo=timezone.utc)
        end_dt = datetime(year, month, last_day, 23, 59, 59, 999000, tzinfo=timezone.utc)

        start_ms = int(start_dt.timestamp() * 1000)
        end_ms = int(end_dt.timestamp() * 1000)
        return start_ms, end_ms
    except Exception:
        # Fallback to last 30 days
        now = _now_ms()
        return now - (30 * 86400 * 1000), now


async def compute_hmis_monthly_indicators(
    db: AsyncSession,
    period: str,
    block_code: str | None = None,
    state_code: str = "default",
) -> dict[str, Any]:
    """Computes all 45+ HMIS monthly indicators from clinical events for the given period.

    Args:
        db: Active AsyncSession.
        period: Period string in YYYY-MM format (e.g. '2026-09').
        block_code: Optional geographical block filter.
        state_code: State code to select state-specific indicator mappings.

    Returns:
        Dictionary containing indicator calculations and metadata for ANM review.
    """
    config = load_hmis_mapping(state_code)
    indicator_defs: dict[str, Any] = config.get("indicators", {})
    start_ms, end_ms = _parse_period_range_ms(period)
    now = _now_ms()

    result_indicators: dict[str, Any] = {}

    try:
        for ind_id, ind_def in indicator_defs.items():
            cat = ind_def.get("category", "General")
            name = ind_def.get("name", ind_id)
            source_encounters = ind_def.get("source_encounters", [])
            obs_code = ind_def.get("observation_code")
            expected_val = ind_def.get("expected_value")
            expected_vals = ind_def.get("expected_values")
            max_val = ind_def.get("max_value")
            min_val = ind_def.get("min_value")
            min_visit_count = ind_def.get("min_visit_count")
            match_any = ind_def.get("match_any", False)

            val = 0

            # Case A: Observation-based indicator
            if obs_code:
                q = (
                    select(func.count(ClinicalObservation.id))
                    .join(ClinicalEncounter, ClinicalObservation.encounter_id == ClinicalEncounter.id)
                    .where(ClinicalEncounter.encounter_date >= start_ms)
                    .where(ClinicalEncounter.encounter_date <= end_ms)
                    .where(ClinicalObservation.observation_code == obs_code)
                )

                if block_code:
                    q = q.join(Member, ClinicalEncounter.member_id == Member.id).where(Member.block_code == block_code)

                if expected_val:
                    q = q.where(ClinicalObservation.value_text == expected_val)
                elif expected_vals:
                    q = q.where(ClinicalObservation.value_text.in_(expected_vals))
                elif max_val is not None:
                    q = q.where(ClinicalObservation.value_numeric <= max_val)
                elif min_val is not None:
                    q = q.where(ClinicalObservation.value_numeric >= min_val)
                elif match_any:
                    # Non-null value matches
                    q = q.where(
                        (ClinicalObservation.value_text.isnot(None)) | (ClinicalObservation.value_numeric.isnot(None))
                    )

                res = await db.execute(q)
                val = res.scalar() or 0

            # Case B: Multi-visit frequency indicator (e.g. 4+ ANC visits or 6+ HBNC visits)
            elif min_visit_count is not None:
                subq = (
                    select(ClinicalEncounter.member_id)
                    .where(ClinicalEncounter.encounter_type.in_(source_encounters))
                    .where(ClinicalEncounter.encounter_date >= start_ms)
                    .where(ClinicalEncounter.encounter_date <= end_ms)
                )
                if block_code:
                    subq = subq.join(Member, ClinicalEncounter.member_id == Member.id).where(
                        Member.block_code == block_code
                    )

                subq = subq.group_by(ClinicalEncounter.member_id).having(func.count(ClinicalEncounter.id) >= min_visit_count)
                res = await db.execute(select(func.count()).select_from(subq.subquery()))
                val = res.scalar() or 0

            # Case C: Encounter-type based indicator
            elif source_encounters:
                q = (
                    select(func.count(ClinicalEncounter.id))
                    .where(ClinicalEncounter.encounter_type.in_(source_encounters))
                    .where(ClinicalEncounter.encounter_date >= start_ms)
                    .where(ClinicalEncounter.encounter_date <= end_ms)
                )
                if block_code:
                    q = q.join(Member, ClinicalEncounter.member_id == Member.id).where(Member.block_code == block_code)

                filter_field = ind_def.get("filter_field")
                if filter_field == "trimester" and ind_def.get("filter_value") == 1:
                    # Trimester 1 check (e.g. within 84 days)
                    q = q.where(ClinicalEncounter.visit_notes.like("%trimester:1%"))
                elif filter_field == "trimester_gt" and ind_def.get("filter_value") == 1:
                    q = q.where(~ClinicalEncounter.visit_notes.like("%trimester:1%"))

                res = await db.execute(q)
                val = res.scalar() or 0

            result_indicators[ind_id] = {
                "id": ind_id,
                "category": cat,
                "name": name,
                "value": int(val),
            }

    except Exception as exc:
        logger.error("Error computing HMIS monthly indicators: %s", exc, exc_info=True)
        incident = IntegrationIncident(
            id=f"inc_{uuid.uuid4().hex[:12]}",
            system_name="HMIS",
            record_type="MONTHLY_INDICATOR_COMPUTE",
            external_id=period,
            error_code="COMPUTATION_ERROR",
            error_message=str(exc),
            status="open",
            created_at=now,
        )
        db.add(incident)
        await db.commit()

    return {
        "period": period,
        "block_code": block_code or "ALL",
        "state_code": state_code,
        "status": "draft_for_anm_review",
        "total_indicators": len(result_indicators),
        "computed_at": now,
        "approved_by": None,
        "approved_at": None,
        "approval_notes": None,
        "indicators": result_indicators,
    }


def approve_hmis_monthly_indicators(
    report_data: dict[str, Any],
    anm_id: str,
    notes: str | None = "Approved by ANM after local review",
) -> dict[str, Any]:
    """Marks computed HMIS monthly indicators as reviewed and approved by ANM (Req 35.6)."""
    updated = dict(report_data)
    updated["status"] = "anm_approved"
    updated["approved_by"] = anm_id
    updated["approved_at"] = _now_ms()
    updated["approval_notes"] = notes
    return updated


async def export_hmis_template_csv(
    db: AsyncSession,
    indicators_data: dict[str, Any],
    exported_by: str = "ANM_SUBMISSION",
) -> str:
    """Exports HMIS indicators into a standard MoHFW bulk-upload CSV template.

    Also logs the outbound export event to OutboundSharingLog for DPDP compliance (Req 35.7).
    """
    output = io.StringIO()
    writer = csv.writer(output)

    # Write official HMIS metadata header
    writer.writerow(["HMIS_MONTHLY_REPORT", indicators_data.get("period", ""), indicators_data.get("block_code", "")])
    writer.writerow([
        "Indicator_Code",
        "Category",
        "Indicator_Description",
        "Value",
        "Reporting_Period",
        "Block_Code",
        "Approval_Status",
        "Approved_By",
    ])

    period = indicators_data.get("period", "")
    block_code = indicators_data.get("block_code", "")
    status = indicators_data.get("status", "draft_for_anm_review")
    approved_by = indicators_data.get("approved_by", "PENDING_APPROVAL")

    indicators = indicators_data.get("indicators", {})
    for ind_id, ind_info in indicators.items():
        writer.writerow([
            ind_id,
            ind_info.get("category", ""),
            ind_info.get("name", ""),
            ind_info.get("value", 0),
            period,
            block_code,
            status,
            approved_by,
        ])

    csv_content = output.getvalue()

    # Log outbound sharing to OutboundSharingLog (Req 35.7)
    now = _now_ms()
    db.add(
        OutboundSharingLog(
            id=f"share_hmis_{uuid.uuid4().hex[:12]}",
            target_system="HMIS",
            record_type="MONTHLY_INDICATORS_EXPORT",
            record_id=f"{period}_{block_code}",
            recipient="MoHFW National HMIS Portal",
            shared_by=exported_by,
            status="success",
            created_at=now,
        )
    )
    await db.commit()

    return csv_content
