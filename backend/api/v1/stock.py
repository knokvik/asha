"""Supply chain and stock management endpoints for PHC and District dashboards.

Implements Requirement 30.6:
- Surfacing stock-outs in PHC and district supply-chain dashboards.
- Aggregated supply chain metrics and critical stock deficit alerts.
"""
from __future__ import annotations

from typing import Any
import uuid

from fastapi import APIRouter, Depends, Header
from jose import JWTError
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from core.multi_tenant import TenantContext, set_tenant_context
from core.security import decode_token
from db.session import get_db
from models.db.models import StockItem, StockOutEvent

router = APIRouter(prefix="/stock", tags=["stock"])


async def _get_optional_tenant(authorization: str | None = Header(None)) -> TenantContext:
    if not authorization or not authorization.startswith("Bearer "):
        ctx = TenantContext(worker_id="system", role="SYSTEM", block_code="default")
        set_tenant_context(ctx)
        return ctx

    token = authorization.removeprefix("Bearer ")
    try:
        payload = decode_token(token)
    except JWTError:
        ctx = TenantContext(worker_id="system", role="SYSTEM", block_code="default")
        set_tenant_context(ctx)
        return ctx

    ctx = TenantContext(
        worker_id=payload.get("sub", "system"),
        role=payload.get("role", "SYSTEM"),
        state_code=payload.get("state_code", ""),
        district_code=payload.get("district_code", ""),
        block_code=payload.get("block_code", ""),
        area_villages=payload.get("area_villages", []),
    )
    set_tenant_context(ctx)
    return ctx


class RecordStockOutRequest(BaseModel):
    worker_id: str
    item_id: str
    item_code: str
    item_name: str
    stock_out_date: str


@router.post("/record-stockout")
async def record_stockout(
    req: RecordStockOutRequest,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Records a stock-out event for an ASHA worker (Requirement 30.6)."""
    event = StockOutEvent(
        id=str(uuid.uuid4()),
        worker_id=req.worker_id,
        item_id=req.item_id,
        item_code=req.item_code,
        item_name=req.item_name,
        stock_out_date=req.stock_out_date,
    )
    db.add(event)
    await db.commit()
    return {
        "status": "recorded",
        "id": event.id,
        "item_name": event.item_name,
        "stock_out_date": event.stock_out_date,
    }


@router.get("/phc-dashboard")
async def get_phc_stock_dashboard(
    worker_id: str | None = None,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Surfaces stock-outs, low-stock items, and inventory status for the PHC workspace (Requirement 30.6)."""
    # 1. Fetch stock items
    query = select(StockItem)
    if worker_id:
        query = query.where(StockItem.worker_id == worker_id)
    items_res = await db.execute(query)
    all_items = items_res.scalars().all()

    low_stock = []
    for item in all_items:
        qty = item.quantity or 0.0
        thresh = item.min_threshold or 5.0
        if qty <= thresh:
            low_stock.append({
                "id": item.id,
                "worker_id": item.worker_id,
                "item_code": item.item_code,
                "item_name": item.item_name,
                "quantity": qty,
                "min_threshold": thresh,
                "unit": item.unit,
                "is_stocked_out": qty <= 0.0,
            })

    # 2. Fetch stock-out events
    so_query = select(StockOutEvent).order_by(StockOutEvent.server_received_at.desc())
    if worker_id:
        so_query = so_query.where(StockOutEvent.worker_id == worker_id)
    so_res = await db.execute(so_query)
    stock_outs = [
        {
            "id": so.id,
            "worker_id": so.worker_id,
            "item_id": so.item_id,
            "item_code": so.item_code,
            "item_name": so.item_name,
            "stock_out_date": so.stock_out_date,
            "recorded_at": so.server_received_at.isoformat() if so.server_received_at else None,
        }
        for so in so_res.scalars().all()
    ]

    return {
        "total_items_tracked": len(all_items),
        "low_stock_count": len(low_stock),
        "stock_out_events_count": len(stock_outs),
        "low_stock_items": low_stock,
        "stock_outs": stock_outs,
    }


@router.get("/district-dashboard")
async def get_district_stock_dashboard(
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """District-level aggregation of stock deficits across all PHCs and ASHAs (Requirement 30.6)."""
    # Aggregated stock-out counts by item_name
    so_query = select(
        StockOutEvent.item_code,
        StockOutEvent.item_name,
        func.count(StockOutEvent.id).label("stockout_count"),
    ).group_by(StockOutEvent.item_code, StockOutEvent.item_name)

    so_res = await db.execute(so_query)
    item_aggregates = [
        {
            "item_code": row[0],
            "item_name": row[1],
            "stock_out_count": row[2],
        }
        for row in so_res.all()
    ]

    # Total distinct workers facing stock-outs
    worker_count_res = await db.execute(
        select(func.count(func.distinct(StockOutEvent.worker_id)))
    )
    affected_workers = worker_count_res.scalar() or 0

    return {
        "total_stock_out_events": sum(item["stock_out_count"] for item in item_aggregates),
        "affected_workers_count": affected_workers,
        "stock_outs_by_item": item_aggregates,
        "critical_supply_chain_deficits": [
            item for item in item_aggregates if item["stock_out_count"] >= 3
        ],
    }
