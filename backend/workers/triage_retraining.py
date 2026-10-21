"""Prepare de-identified, clinician-confirmed outcomes for a future model run.

This is intentionally an export/manifest stub: it never retrains or deploys a
model automatically. A clinical lead must review the export and approve a new
version before training is run outside the live service.
"""
from __future__ import annotations

import json
from collections import Counter
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.desk import DeskOutcome, DeskTicket


async def collect_confirmed_outcomes(
    db: AsyncSession, *, limit: int = 10_000
) -> list[dict[str, Any]]:
    """Return de-identified ticket features paired with confirmed outcomes."""
    rows = await db.execute(
        select(DeskTicket, DeskOutcome)
        .join(DeskOutcome, DeskOutcome.ticket_id == DeskTicket.id)
        .order_by(DeskOutcome.recorded_at.asc())
        .limit(limit)
    )
    records: list[dict[str, Any]] = []
    for ticket, outcome in rows.all():
        payload = json.loads(ticket.payload_json or "{}")
        for key in (
            "name",
            "location",
            "attachments_json",
            "sms",
            "additional_details",
        ):
            payload.pop(key, None)
        records.append(
            {
                "ticket_id": ticket.id,
                "engine_version": ticket.engine_version,
                "model_version": ticket.model_version,
                "triage_flag": ticket.priority,
                "features": payload,
                "outcome_label_for_ml": outcome.outcome_label_for_ml,
                "outcome_recorded_at": outcome.recorded_at.isoformat(),
            }
        )
    return records


def next_model_manifest(
    records: list[dict[str, Any]], *, candidate_version: str
) -> dict[str, Any]:
    """Return a reviewable manifest; model training and deployment remain manual."""
    labels = Counter(str(row["outcome_label_for_ml"]) for row in records)
    return {
        "candidate_model_version": candidate_version,
        "records": len(records),
        "outcome_labels": dict(sorted(labels.items())),
        "requires_clinical_approval": True,
        "automatic_deployment": False,
    }
