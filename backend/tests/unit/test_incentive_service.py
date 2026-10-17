"""Unit tests for backend incentive service and API endpoints (Requirements 53.1–53.4, 54.1–54.6, Task 13.2).

Validates:
- Effective-dated versioned catalogues and historical rate lookup (Req 53.2, Property 11)
- Deterministic idempotency and event deduplication (Req 54.1, Property 10)
- Multi-component rates (Req 53.3)
- Duplicate claim detection across multiple workers with ANM review queue (Req 54.6)
- API endpoints for catalogue, rates, events, and duplicates
"""
from __future__ import annotations

from datetime import datetime

import pytest

from models.db.models import Member, User
from services.incentive_service import IncentiveService


@pytest.mark.asyncio
async def test_catalogue_versioning_and_historical_rate_invariant(db_session):
    """Property 11: Rate lookup for historical claims uses catalogue active on event date."""
    cat_2023_data = {
        "version_id": "TEST_CAT_2023",
        "state_code": "DEFAULT",
        "items": [
            {
                "activity_code": "ANC_REG_EARLY",
                "rates": {
                    "fixed_honorarium": 0.0,
                    "performance_incentive": 75.0,
                    "state_top_up": 25.0,
                    "connectivity_allowance": 0.0,
                },
            },
            {
                "activity_code": "HBNC_COMPLETE",
                "rates": {
                    "fixed_honorarium": 0.0,
                    "performance_incentive": 200.0,
                    "state_top_up": 0.0,
                    "connectivity_allowance": 0.0,
                },
            },
        ],
    }

    cat_2024_data = {
        "version_id": "TEST_CAT_2024",
        "state_code": "DEFAULT",
        "items": [
            {
                "activity_code": "ANC_REG_EARLY",
                "rates": {
                    "fixed_honorarium": 0.0,
                    "performance_incentive": 100.0,
                    "state_top_up": 50.0,
                    "connectivity_allowance": 0.0,
                },
            },
            {
                "activity_code": "HBNC_COMPLETE",
                "rates": {
                    "fixed_honorarium": 0.0,
                    "performance_incentive": 250.0,
                    "state_top_up": 50.0,
                    "connectivity_allowance": 0.0,
                },
            },
        ],
    }

    # Publish 2023 catalogue
    await IncentiveService.publish_catalogue(
        db_session,
        version_id="TEST_CAT_2023",
        state_code="DEFAULT",
        effective_from=datetime(2023, 1, 1),
        catalogue_data=cat_2023_data,
        effective_to=datetime(2023, 12, 31, 23, 59, 59),
    )

    # Publish 2024 catalogue (open ended)
    await IncentiveService.publish_catalogue(
        db_session,
        version_id="TEST_CAT_2024",
        state_code="DEFAULT",
        effective_from=datetime(2024, 1, 1),
        catalogue_data=cat_2024_data,
        effective_to=None,
    )
    await db_session.commit()

    # Invariant: 2023 event returns 2023 rates (75 + 25 = 100)
    rate_2023 = await IncentiveService.get_rate_for_event(
        db_session, "ANC_REG_EARLY", datetime(2023, 9, 15)
    )
    assert rate_2023["performance_incentive"] == 75.0
    assert rate_2023["state_top_up"] == 25.0
    assert rate_2023["total_rate"] == 100.0

    # Invariant: 2024 event returns 2024 rates (100 + 50 = 150)
    rate_2024 = await IncentiveService.get_rate_for_event(
        db_session, "ANC_REG_EARLY", datetime(2024, 5, 20)
    )
    assert rate_2024["performance_incentive"] == 100.0
    assert rate_2024["state_top_up"] == 50.0
    assert rate_2024["total_rate"] == 150.0


@pytest.mark.asyncio
async def test_idempotent_event_logging(db_session):
    """Property 10: Recording same eligible event N times produces exactly one record."""
    event_date = datetime(2024, 4, 10)
    member_id = "mem_test_dedup_01"
    activity_code = "ANC_REG_EARLY"

    # Seed test worker and member
    worker = User(
        id="worker_dedup_01",
        asha_id="ASHA_DEDUP_01",
        name="Asha Dedup",
        role="ASHA",
        is_active=True,
    )
    member = Member(
        id=member_id,
        name="Sunita Sharma",
        sex="F",
        created_by="worker_dedup_01",
    )
    db_session.add(worker)
    db_session.add(member)
    await db_session.commit()

    # 1. First record attempt: created=True
    ev1, created1 = await IncentiveService.record_incentive_event(
        db_session,
        worker_id="worker_dedup_01",
        member_id=member_id,
        activity_code=activity_code,
        event_date=event_date,
    )
    await db_session.commit()
    assert created1 is True
    assert ev1.status == "eligible"

    # 2. Replay attempt 1: created=False, same ID
    ev2, created2 = await IncentiveService.record_incentive_event(
        db_session,
        worker_id="worker_dedup_01",
        member_id=member_id,
        activity_code=activity_code,
        event_date=event_date,
    )
    assert created2 is False
    assert ev2.id == ev1.id
    assert ev2.idempotency_key == ev1.idempotency_key

    # 3. Replay attempt 2: created=False, same ID
    ev3, created3 = await IncentiveService.record_incentive_event(
        db_session,
        worker_id="worker_dedup_01",
        member_id=member_id,
        activity_code=activity_code,
        event_date=event_date,
    )
    assert created3 is False
    assert ev3.id == ev1.id


@pytest.mark.asyncio
async def test_duplicate_claim_detection_across_workers(db_session):
    """Requirement 54.6: Same event claimed by two workers is detected and flagged for ANM review."""
    member_id = "mem_deliv_conflict_01"
    activity_code = "INST_DELIVERY_ESCORT"
    event_date = datetime(2024, 6, 12)

    # Seed 2 ASHAs and the beneficiary member
    w1 = User(
        id="worker_asha_1",
        asha_id="ASHA_01",
        name="Asha One",
        role="ASHA",
        is_active=True,
    )
    w2 = User(
        id="worker_asha_2",
        asha_id="ASHA_02",
        name="Asha Two",
        role="ASHA",
        is_active=True,
    )
    member = Member(
        id=member_id,
        name="Radha Devi",
        sex="F",
        created_by="worker_asha_1",
    )
    db_session.add_all([w1, w2, member])
    await db_session.commit()

    # Worker 1 logs delivery escort
    ev1, created1 = await IncentiveService.record_incentive_event(
        db_session,
        worker_id="worker_asha_1",
        member_id=member_id,
        activity_code=activity_code,
        event_date=event_date,
    )
    await db_session.commit()
    assert created1 is True
    assert ev1.status == "eligible"

    # Worker 2 logs delivery escort for the same delivery event
    ev2, created2 = await IncentiveService.record_incentive_event(
        db_session,
        worker_id="worker_asha_2",
        member_id=member_id,
        activity_code=activity_code,
        event_date=event_date,
    )
    await db_session.commit()

    # Conflicting claim detected! Status must be flagged_review
    assert ev2.status == "flagged_review"
    assert "Duplicate claim conflict" in ev2.flagged_reason
    assert "worker_asha_1" in ev2.flagged_reason
    assert "worker_asha_2" in ev2.flagged_reason

    # The existing event for worker 1 should also be marked flagged_review
    assert ev1.status == "flagged_review"

    # Query duplicate queue for ANM review
    flagged = await IncentiveService.get_flagged_duplicate_events(db_session)
    flagged_ids = [f.id for f in flagged]
    assert ev1.id in flagged_ids
    assert ev2.id in flagged_ids


@pytest.mark.asyncio
async def test_incentives_api_endpoints(async_client, db_session):
    """Validates FastAPI routes for catalogue, rates, events, and duplicate review."""
    # 1. GET /api/v1/incentives/catalogue
    cat_resp = await async_client.get("/api/v1/incentives/catalogue")
    assert cat_resp.status_code == 200
    cat_data = cat_resp.json()
    assert "version_id" in cat_data
    assert any(i["activity_code"] == "ANC_REG_EARLY" for i in cat_data["items"])

    # 2. GET /api/v1/incentives/rate-lookup
    rate_resp = await async_client.get(
        "/api/v1/incentives/rate-lookup?activity_code=ANC_REG_EARLY&event_date=2024-06-01"
    )
    assert rate_resp.status_code == 200
    rates = rate_resp.json()["rates"]
    assert rates["performance_incentive"] == 100.0
    assert rates["state_top_up"] == 50.0
    assert rates["total_rate"] == 150.0

    # 3. POST /api/v1/incentives/events
    post_resp = await async_client.post(
        "/api/v1/incentives/events",
        json={
            "member_id": "mem_api_test_01",
            "activity_code": "CBAC_SCREENING",
            "event_date": "2024-06-01T10:00:00",
            "status": "eligible",
        },
    )
    assert post_resp.status_code == 200
    ev_data = post_resp.json()
    assert ev_data["created"] is True
    assert ev_data["activity_code"] == "CBAC_SCREENING"

    # 4. Duplicate POST returns created=False (idempotency)
    dup_resp = await async_client.post(
        "/api/v1/incentives/events",
        json={
            "member_id": "mem_api_test_01",
            "activity_code": "CBAC_SCREENING",
            "event_date": "2024-06-01T10:00:00",
            "status": "eligible",
        },
    )
    assert dup_resp.status_code == 200
    assert dup_resp.json()["created"] is False
    assert dup_resp.json()["id"] == ev_data["id"]

    # 5. GET /api/v1/incentives/duplicates
    dup_list_resp = await async_client.get("/api/v1/incentives/duplicates")
    assert dup_list_resp.status_code == 200
    assert isinstance(dup_list_resp.json(), list)
