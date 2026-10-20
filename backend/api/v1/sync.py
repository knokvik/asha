"""Sync push/pull API endpoints — Task 2.4 & 2.5.

POST /api/v1/sync/push  — Decompress gzip body, detect duplicate batch_id,
                           apply idempotent upserts with conflict resolution.
GET  /api/v1/sync/pull  — Return watermark-based delta payload (compressed).

Requirements: 31.1, 31.2, 32.2, 32.3
"""
from __future__ import annotations

import gzip
import json

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from fastapi.responses import Response
from jose import JWTError
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from core.multi_tenant import TenantContext, set_tenant_context
from core.security import decode_token
from db.session import get_db
from models.db.models import AuditLog
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
    _: TenantContext = Depends(_get_tenant),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Return persisted packet history for the live web sync panel."""
    result = await db.execute(
        select(AuditLog).order_by(desc(AuditLog.server_timestamp)).limit(limit)
    )
    rows = result.scalars().all()
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
            }
            for row in rows
        ]
    }
