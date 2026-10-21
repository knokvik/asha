"""Sync push/pull API endpoints — Task 2.4 & 2.5.

POST /api/v1/sync/push  — Decompress gzip body, detect duplicate batch_id,
                           apply idempotent upserts with conflict resolution.
GET  /api/v1/sync/pull  — Return watermark-based delta payload (compressed).

Requirements: 31.1, 31.2, 32.2, 32.3
"""
from __future__ import annotations

import base64
import gzip
import json
import time
from collections import defaultdict

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from fastapi.responses import Response
from jose import JWTError
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from core.multi_tenant import TenantContext, set_tenant_context
from core.security import decode_token
from db.session import get_db
from models.db.models import AreaNotification, AuditLog, TriageTicket
from models.schemas.schemas import SyncPullResponse, SyncPushRequest, SyncPushResponse
from services.sync_service import SyncService

router = APIRouter(prefix="/sync", tags=["sync"])


async def _get_tenant(authorization: str = Header(...)) -> TenantContext:
    """Decode JWT from Authorization header and set tenant context."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing Bearer token")
    token = authorization.removeprefix("Bearer ")
    try:
        payload = decode_token(token)
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    ctx = TenantContext(
        worker_id=payload.get("sub", ""),
        role=payload.get("role", ""),
        state_code=payload.get("state_code", ""),
        district_code=payload.get("district_code", ""),
        block_code=payload.get("block_code", ""),
        area_villages=payload.get("area_villages", []),
    )
    set_tenant_context(ctx)
    return ctx


@router.post("/push", response_model=SyncPushResponse, status_code=status.HTTP_200_OK)
async def sync_push(
    request: Request,
    tenant: TenantContext = Depends(_get_tenant),
    db: AsyncSession = Depends(get_db),
) -> SyncPushResponse:
    """Accept a gzip-compressed sync batch and apply it idempotently.

    Content-Encoding: gzip is supported; falls back to plain JSON.
    Requirements: 31.2, 32.2, 32.3
    """
    raw = await request.body()
    content_encoding = request.headers.get("content-encoding", "").lower()
    if "gzip" in content_encoding:
        raw = gzip.decompress(raw)

    try:
        body = SyncPushRequest.model_validate_json(raw)
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))

    svc = SyncService(db)
    return await svc.apply_batch(body, block_code=tenant.block_code)


@router.get("/pull", response_model=SyncPullResponse, status_code=status.HTTP_200_OK)
async def sync_pull(
    worker_id: str = Query(...),
    watermarks: str = Query(default="{}"),
    tenant: TenantContext = Depends(_get_tenant),
    db: AsyncSession = Depends(get_db),
    accept_encoding: str = Header(default=""),
) -> Response:
    """Return delta records since each table's last watermark.

    Query params:
        worker_id   — ASHA worker ID (validated against JWT sub)
        watermarks  — JSON dict of table → last_seen_server_seq

    Returns gzip-compressed JSON if client accepts it.
    Requirements: 31.1
    """
    if worker_id != tenant.worker_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="worker_id mismatch")

    try:
        wm_dict: dict[str, int] = json.loads(watermarks)
    except json.JSONDecodeError:
        wm_dict = {}

    svc = SyncService(db)
    records, new_watermarks, has_more = await svc.get_delta(
        worker_id=worker_id,
        watermarks=wm_dict,
        block_code=tenant.block_code,
    )

    response_body = SyncPullResponse(
        records=records,
        server_watermarks=new_watermarks,
        has_more=has_more,
    ).model_dump_json().encode()

    if "gzip" in accept_encoding.lower():
        return Response(
            content=gzip.compress(response_body),
            media_type="application/json",
            headers={"Content-Encoding": "gzip"},
        )
    return Response(content=response_body, media_type="application/json")


@router.get("/activity")
async def sync_activity(
    limit: int = Query(default=100, ge=1, le=500),
    tenant: TenantContext = Depends(_get_tenant),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Return persisted packet history for the live web sync panel."""
    query = select(AuditLog).order_by(desc(AuditLog.server_timestamp)).limit(limit)
    if tenant.role == "ASHA":
        query = query.where(AuditLog.changed_by == tenant.worker_id)
    result = await db.execute(query)
    rows = result.scalars().all()
    ticket_ids = [row.record_id for row in rows if row.table_name == "triage_tickets"]
    tickets: dict[str, TriageTicket] = {}
    if ticket_ids:
        ticket_rows = await db.execute(
            select(TriageTicket).where(TriageTicket.id.in_(ticket_ids))
        )
        tickets = {ticket.id: ticket for ticket in ticket_rows.scalars()}
    return {
        "packets": [
            {
                "id": row.id,
                "table": row.table_name,
                "record_id": row.record_id,
                "worker_id": row.changed_by,
                "device_id": row.device_id,
                "app_version": row.app_version,
                "received_at": row.server_timestamp,
                "device_timestamp": row.device_timestamp,
                "operation": row.new_value if row.field_name == "__packet__" else "update",
                "status": "synced",
                **_ticket_activity(tickets.get(row.record_id)),
            }
            for row in rows
        ]
    }


@router.get("/hotspots")
async def sync_hotspots(
    lookback_days: int = Query(default=28, ge=7, le=90),
    tenant: TenantContext = Depends(_get_tenant),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Return privacy-preserving cross-worker disease signals for one block.

    This endpoint deliberately returns only ward/module aggregates. It never
    exposes patient names, ticket IDs, or free-text clinical notes. A signal
    becomes an adaptive hotspot only after reports from at least two distinct
    workers in the same assigned block.
    """
    if not tenant.block_code:
        return {
            "generated_at": int(time.time() * 1000),
            "counts": [],
            "modules": [],
            "hotspots": [],
            "notifications": [],
        }

    since = int(time.time() * 1000) - lookback_days * 24 * 60 * 60 * 1000
    result = await db.execute(
        select(TriageTicket).where(
            TriageTicket.block_code == tenant.block_code,
            TriageTicket.created_at >= since,
            TriageTicket.ward_id.isnot(None),
        )
    )
    tickets = result.scalars().all()

    module_meta = {
        "dengue": ("dengue_like", 3),
        "measles": ("measles_like", 2),
        "diarrhoea_cluster": ("acute_diarrhoea", 8),
        "aes": ("aes", 1),
    }
    grouped: dict[tuple[str, str], dict[str, object]] = defaultdict(
        lambda: {"cases": 0, "workers": set(), "latest": 0}
    )
    for ticket in tickets:
        ward_id = ticket.ward_id
        if not ward_id:
            continue
        try:
            modules = json.loads(ticket.modules_json or "[]")
        except json.JSONDecodeError:
            modules = []
        if not isinstance(modules, list):
            continue
        for module_id in modules:
            module = module_meta.get(str(module_id))
            if module is None:
                continue
            condition, _ = module
            bucket = grouped[(ward_id, str(module_id))]
            bucket["cases"] = int(bucket["cases"]) + 1
            workers = bucket["workers"]
            if isinstance(workers, set) and ticket.worker_id:
                workers.add(ticket.worker_id)
            bucket["latest"] = max(int(bucket["latest"]), int(ticket.created_at or 0))

    now = int(time.time() * 1000)
    week_index = now // (7 * 24 * 60 * 60 * 1000)
    month = time.gmtime(now / 1000).tm_mon
    counts: list[dict[str, object]] = []
    modules: list[dict[str, object]] = []
    hotspots: list[dict[str, object]] = []
    notifications: list[dict[str, object]] = []
    seen_modules: set[str] = set()
    for (ward_id, module_id), bucket in grouped.items():
        condition, threshold = module_meta[module_id]
        workers = bucket["workers"]
        worker_count = len(workers) if isinstance(workers, set) else 0
        cases = int(bucket["cases"])
        active = worker_count >= 2 and cases >= threshold
        hotspots.append(
            {
                "ward_id": ward_id,
                "module_id": module_id,
                "condition": condition,
                "cases": cases,
                "worker_count": worker_count,
                "active": active,
                "last_reported_at": int(bucket["latest"]),
                "latitude": _mean_coordinate(tickets, ward_id, "latitude"),
                "longitude": _mean_coordinate(tickets, ward_id, "longitude"),
            }
        )
        if not active:
            continue
        counts.append(
            {
                "week_index": week_index,
                "ward_id": ward_id,
                "condition": condition,
                "cases": cases,
            }
        )
        if module_id not in seen_modules:
            seen_modules.add(module_id)
            modules.append(
                {
                    "id": module_id,
                    "condition": condition,
                    "min_cases_per_week": threshold,
                    "lookback_weeks": 4,
                    "seasonal_months": list(range(1, 13)),
                }
            )

        if active:
            notification = await _ensure_area_notification(
                db,
                block_code=tenant.block_code,
                ward_id=ward_id,
                module_id=module_id,
                condition=condition,
                cases=cases,
                worker_count=worker_count,
                created_at=now,
            )
            notifications.append(notification)

    return {
        "generated_at": now,
        "as_of_month": month,
        "lookback_days": lookback_days,
        "block_code": tenant.block_code,
        "counts": counts,
        "modules": modules,
        "hotspots": hotspots,
        "notifications": notifications,
    }


def _mean_coordinate(tickets: list[TriageTicket], ward_id: str, field: str) -> float | None:
    values = [getattr(ticket, field) for ticket in tickets if ticket.ward_id == ward_id]
    numeric = [float(value) for value in values if value is not None]
    return round(sum(numeric) / len(numeric), 6) if numeric else None


async def _ensure_area_notification(
    db: AsyncSession,
    *,
    block_code: str,
    ward_id: str,
    module_id: str,
    condition: str,
    cases: int,
    worker_count: int,
    created_at: int,
) -> dict[str, object]:
    dedupe_key = f"{block_code}:{ward_id}:{module_id}:{created_at // (7 * 24 * 60 * 60 * 1000)}"
    existing = await db.scalar(
        select(AreaNotification).where(AreaNotification.dedupe_key == dedupe_key)
    )
    if existing is None:
        existing = AreaNotification(
            id=f"area-{dedupe_key}",
            block_code=block_code,
            ward_id=ward_id,
            module_id=module_id,
            title=f"Shared area signal: {condition.replace('_', ' ').title()}",
            body=(
                f"{cases} reports from {worker_count} ASHA workers were detected in {ward_id}. "
                "Related triage questions will be added automatically."
            ),
            severity="urgent" if module_id in {"aes", "measles"} else "standard",
            created_at=created_at,
            expires_at=created_at + 28 * 24 * 60 * 60 * 1000,
            dedupe_key=dedupe_key,
        )
        db.add(existing)
        await db.flush()
    return {
        "id": existing.id,
        "ward_id": existing.ward_id,
        "module_id": existing.module_id,
        "title": existing.title,
        "body": existing.body,
        "severity": existing.severity,
        "created_at": existing.created_at,
        "expires_at": existing.expires_at,
    }


@router.get("/triage-tickets/{ticket_id}/attachments/{attachment_index}")
async def triage_attachment(
    ticket_id: str,
    attachment_index: int,
    tenant: TenantContext = Depends(_get_tenant),
    db: AsyncSession = Depends(get_db),
) -> Response:
    """Return one authenticated evidence file without exposing it in activity JSON."""
    ticket = await db.get(TriageTicket, ticket_id)
    if ticket is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="ticket not found")
    if not _can_access_ticket(ticket, tenant):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="ticket is outside your assigned area",
        )
    attachments = _ticket_attachments(ticket)
    if attachment_index < 0 or attachment_index >= len(attachments):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="attachment not found")
    attachment = attachments[attachment_index]
    try:
        if attachment.get("encoding") != "gzip+base64":
            raise ValueError("unsupported evidence encoding")
        content = gzip.decompress(base64.b64decode(str(attachment["data_base64"])))
    except (KeyError, TypeError, ValueError, OSError) as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="attachment could not be decoded",
        ) from exc
    media_type = str(attachment.get("mime_type") or "application/octet-stream")
    extension = "jpg" if media_type == "image/jpeg" else "m4a"
    return Response(
        content=content,
        media_type=media_type,
        headers={
            "Cache-Control": "no-store",
            "Content-Disposition": f'inline; filename="{ticket_id}-{attachment_index}.{extension}"',
        },
    )


def _ticket_activity(ticket: TriageTicket | None) -> dict:
    if ticket is None:
        return {}
    attachments = _ticket_attachments(ticket)
    return {
        "ticket": {
            "id": ticket.id,
            "patient_name": ticket.name,
            "location": ticket.location,
            "flag": ticket.flag,
            "ward_id": ticket.ward_id,
            "details": ticket.additional_details,
            "attachments": [
                {
                    "index": index,
                    "type": attachment.get("type", "file"),
                    "mime_type": attachment.get("mime_type", "application/octet-stream"),
                    "original_bytes": attachment.get("original_bytes"),
                    "url": f"/sync/triage-tickets/{ticket.id}/attachments/{index}",
                }
                for index, attachment in enumerate(attachments)
            ],
        }
    }


def _ticket_attachments(ticket: TriageTicket) -> list[dict]:
    try:
        attachments = json.loads(ticket.attachments_json or "[]")
    except json.JSONDecodeError:
        return []
    return [item for item in attachments if isinstance(item, dict)] if isinstance(attachments, list) else []


def _can_access_ticket(ticket: TriageTicket, tenant: TenantContext) -> bool:
    """Enforce the direct-object check that ORM area filters cannot cover."""
    if tenant.role == "ASHA":
        return ticket.worker_id == tenant.worker_id
    return not tenant.block_code or ticket.block_code == tenant.block_code
