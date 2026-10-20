"""Triage desk routes on the existing /api/v1 app."""
from __future__ import annotations

import gzip
import json
from datetime import datetime

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from fastapi.responses import JSONResponse, Response
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession

from core.security import decode_token
from db.session import get_db
from services.triage_desk import TriageDesk, pack_etag

router = APIRouter(tags=["triage-desk"])


async def _actor(authorization: str | None = Header(default=None)) -> dict:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing Bearer token")
    token = authorization.removeprefix("Bearer ")
    try:
        payload = decode_token(token)
    except JWTError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token") from exc
    return payload


def _now_header(x_now: str | None) -> datetime:
    if not x_now:
        return datetime.utcnow()
    text = x_now.replace("Z", "+00:00")
    parsed = datetime.fromisoformat(text)
    return parsed.replace(tzinfo=None) if parsed.tzinfo else parsed


async def _read_json(request: Request) -> dict:
    raw = await request.body()
    if "gzip" in request.headers.get("content-encoding", "").lower():
        raw = gzip.decompress(raw)
    try:
        body = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=422, detail="invalid json") from exc
    if not isinstance(body, dict):
        raise HTTPException(status_code=422, detail="body must be an object")
    return body


@router.post("/sync/batch")
async def sync_batch(
    request: Request,
    db: AsyncSession = Depends(get_db),
    actor: dict = Depends(_actor),
) -> dict:
    body = await _read_json(request)
    items = body.get("items")
    if not isinstance(items, list):
        raise HTTPException(status_code=422, detail="items must be a list")
    try:
        return await TriageDesk(db).accept_batch(items)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc


@router.get("/packs/latest")
async def latest_pack(
    district_id: str = Query("PCMC"),
    db: AsyncSession = Depends(get_db),
    actor: dict = Depends(_actor),
    if_none_match: str | None = Header(default=None),
) -> Response:
    desk = TriageDesk(db)
    pack = await desk.latest_pack(district_id)
    if pack is None:
        raise HTTPException(status_code=404, detail="no pack")
    if if_none_match == pack.etag:
        return Response(status_code=304, headers={"ETag": pack.etag})
    return JSONResponse(json.loads(pack.body_json), headers={"ETag": pack.etag})


@router.get("/tickets")
async def list_tickets(
    status_filter: str | None = Query(default=None, alias="status"),
    priority: str | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
    actor: dict = Depends(_actor),
) -> dict:
    rows = await TriageDesk(db).list_tickets(status_filter, priority)
    return {"tickets": [_ticket(row) for row in rows]}


@router.get("/tickets/{ticket_id}")
async def get_ticket(
    ticket_id: str,
    db: AsyncSession = Depends(get_db),
    actor: dict = Depends(_actor),
) -> dict:
    ticket = await TriageDesk(db).get_ticket(ticket_id)
    if ticket is None:
        raise HTTPException(status_code=404, detail="ticket not found")
    return _ticket(ticket)


@router.post("/tickets/{ticket_id}/ack")
async def ack_ticket(
    ticket_id: str,
    db: AsyncSession = Depends(get_db),
    actor: dict = Depends(_actor),
    x_now: str | None = Header(default=None),
) -> dict:
    try:
        ticket = await TriageDesk(db).acknowledge(ticket_id, _now_header(x_now))
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="ticket not found") from exc
    return _ticket(ticket)


@router.post("/tickets/{ticket_id}/consult")
async def consult_ticket(
    ticket_id: str,
    db: AsyncSession = Depends(get_db),
    actor: dict = Depends(_actor),
) -> dict:
    try:
        ticket = await TriageDesk(db).start_consult(ticket_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="ticket not found") from exc
    except ValueError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    return _ticket(ticket)


@router.post("/tickets/{ticket_id}/outcome")
async def outcome_ticket(
    ticket_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    actor: dict = Depends(_actor),
) -> dict:
    body = await _read_json(request)
    try:
        ticket = await TriageDesk(db).record_outcome(ticket_id, body)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="ticket not found") from exc
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    return _ticket(ticket)


@router.get("/analytics/heatmap")
async def heatmap(
    district_id: str = Query("PCMC"),
    week: int = Query(11),
    db: AsyncSession = Depends(get_db),
    actor: dict = Depends(_actor),
) -> dict:
    return await TriageDesk(db).heatmap(district_id, week)


@router.get("/ashas/{asha_id}/stats")
async def asha_stats(
    asha_id: str,
    db: AsyncSession = Depends(get_db),
    actor: dict = Depends(_actor),
) -> dict:
    return await TriageDesk(db).asha_stats(asha_id)


@router.post("/jobs/escalate")
async def escalate(
    db: AsyncSession = Depends(get_db),
    actor: dict = Depends(_actor),
    x_now: str | None = Header(default=None),
) -> dict:
    notices = await TriageDesk(db).escalate(_now_header(x_now))
    return {"escalated": notices}


def _ticket(row) -> dict:
    return {
        "id": row.id,
        "referral_id": row.referral_id,
        "priority": row.priority,
        "status": row.status,
        "district_id": row.district_id,
        "ward_id": row.ward_id,
        "asha_id": row.asha_id,
        "created_at": row.created_at.isoformat() if row.created_at else None,
        "sla_due_at": row.sla_due_at.isoformat() if row.sla_due_at else None,
        "escalated_level": row.escalated_level,
        "etag_hint": pack_etag(0),
    }
