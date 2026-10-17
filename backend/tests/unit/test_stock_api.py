"""Unit tests for PHC and District Supply Chain Stock Dashboards (Requirement 30.6, Task 12.6)."""
from __future__ import annotations

import pytest

from models.db.models import StockItem


@pytest.mark.asyncio
async def test_record_stockout_and_surface_in_phc_dashboard(async_client, db_session):
    # Seed a stock item with 0 quantity
    stock_item = StockItem(
        id="item_stockout_01",
        worker_id="asha_worker_101",
        item_code="zinc_tabs",
        item_name="Zinc Tablets (20mg)",
        quantity=0.0,
        min_threshold=20.0,
        unit="tablets",
        last_updated_at=1770000000000,
    )
    db_session.add(stock_item)
    await db_session.commit()

    # 1. Record stockout via API
    resp = await async_client.post(
        "/api/v1/stock/record-stockout",
        json={
            "worker_id": "asha_worker_101",
            "item_id": "item_stockout_01",
            "item_code": "zinc_tabs",
            "item_name": "Zinc Tablets (20mg)",
            "stock_out_date": "2026-10-15T18:00:00Z",
        },
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "recorded"
    assert body["item_name"] == "Zinc Tablets (20mg)"

    # 2. Query PHC stock dashboard
    phc_resp = await async_client.get("/api/v1/stock/phc-dashboard?worker_id=asha_worker_101")
    assert phc_resp.status_code == 200
    phc_data = phc_resp.json()
    assert phc_data["total_items_tracked"] >= 1
    assert phc_data["stock_out_events_count"] >= 1
    assert any(item["item_code"] == "zinc_tabs" and item["is_stocked_out"] for item in phc_data["low_stock_items"])

    # 3. Query District stock dashboard
    dist_resp = await async_client.get("/api/v1/stock/district-dashboard")
    assert dist_resp.status_code == 200
    dist_data = dist_resp.json()
    assert dist_data["total_stock_out_events"] >= 1
    assert dist_data["affected_workers_count"] >= 1
    assert any(item["item_code"] == "zinc_tabs" for item in dist_data["stock_outs_by_item"])

