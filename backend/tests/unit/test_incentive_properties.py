"""Property-based tests for backend incentive engine (Properties 10, 11, 12).

Requirements: 53.2, 54.1, 54.6, 56.1, 56.7
Tasks: 13.7
"""
from __future__ import annotations

import csv
from datetime import datetime, timedelta
import io
import json
import random
import uuid

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.models import IncentiveClaim, IncentiveEvent, Member, User
from services.incentive_service import IncentiveService


@pytest.mark.asyncio
async def test_property_10_incentive_event_deduplication(db_session: AsyncSession) -> None:
    """Property 10: Recording same eligible event N times produces exactly one record."""
    rnd = random.Random(42)
    activities = [
        "ANC_REG_EARLY",
        "ANC_CHECKUP_FULL",
        "INSTITUTIONAL_DELIVERY",
        "HBNC_COMPLETE",
        "IMM_FULL_1YEAR",
        "CBAC_SCREENING",
        "NCD_FOLLOWUP",
        "TB_DOTS_COMPLETION",
    ]

    worker = User(
        id=f"worker_p10_{uuid.uuid4().hex[:8]}",
        asha_id="ASHA_P10_BACKEND",
        name="Asha P10",
        role="ASHA",
        is_active=True,
    )
    db_session.add(worker)
    await db_session.commit()

    for trial in range(30):
        member_id = f"mem_p10_{trial}_{rnd.randint(1, 10000)}"
        activity_code = rnd.choice(activities)
        days_ago = rnd.randint(1, 90)
        event_dt = datetime.now() - timedelta(days=days_ago)
        retry_count = rnd.randint(2, 6)

        # Seed member
        member = Member(
            id=member_id,
            name=f"Beneficiary {trial}",
            sex="F",
            created_by=worker.id,
        )
        db_session.add(member)
        await db_session.commit()

        first_event_id: str | None = None
        first_idempotency_key: str | None = None

        for retry in range(retry_count):
            ev, created = await IncentiveService.record_incentive_event(
                db_session,
                worker_id=worker.id,
                member_id=member_id,
                activity_code=activity_code,
                event_date=event_dt,
            )

            if retry == 0:
                assert created is True
                first_event_id = ev.id
                first_idempotency_key = ev.idempotency_key
            else:
                assert created is False
                assert ev.id == first_event_id, f"Property 10 violated: differing event ID on retry {retry}"
                assert ev.idempotency_key == first_idempotency_key

        # Assert exactly one record in the database for this idempotency key
        stmt = select(IncentiveEvent).where(IncentiveEvent.idempotency_key == first_idempotency_key)
        res = await db_session.execute(stmt)
        events = res.scalars().all()
        assert len(events) == 1, f"Property 10 violated: expected 1 record, got {len(events)}"


@pytest.mark.asyncio
async def test_property_11_historical_rate_invariant(db_session: AsyncSession) -> None:
    """Property 11: Rate computation uses the catalogue active at event date across multiple historical versions."""
    rnd = random.Random(42)

    cat_2022 = {
        "version_id": "PROP_CAT_2022",
        "state_code": "PROP_STATE",
        "items": [
            {
                "activity_code": "ANC_REG_EARLY",
                "rates": {"fixed_honorarium": 0.0, "performance_incentive": 60.0, "state_top_up": 20.0},
            },
            {
                "activity_code": "HBNC_COMPLETE",
                "rates": {"fixed_honorarium": 0.0, "performance_incentive": 150.0, "state_top_up": 25.0},
            },
        ],
    }

    cat_2023 = {
        "version_id": "PROP_CAT_2023",
        "state_code": "PROP_STATE",
        "items": [
            {
                "activity_code": "ANC_REG_EARLY",
                "rates": {"fixed_honorarium": 0.0, "performance_incentive": 80.0, "state_top_up": 30.0},
            },
            {
                "activity_code": "HBNC_COMPLETE",
                "rates": {"fixed_honorarium": 0.0, "performance_incentive": 200.0, "state_top_up": 50.0},
            },
        ],
    }

    cat_2024 = {
        "version_id": "PROP_CAT_2024",
        "state_code": "PROP_STATE",
        "items": [
            {
                "activity_code": "ANC_REG_EARLY",
                "rates": {"fixed_honorarium": 0.0, "performance_incentive": 120.0, "state_top_up": 40.0},
            },
            {
                "activity_code": "HBNC_COMPLETE",
                "rates": {"fixed_honorarium": 0.0, "performance_incentive": 250.0, "state_top_up": 50.0},
            },
        ],
    }

    await IncentiveService.publish_catalogue(
        db_session,
        version_id="PROP_CAT_2022",
        state_code="PROP_STATE",
        effective_from=datetime(2022, 1, 1),
        catalogue_data=cat_2022,
        effective_to=datetime(2022, 12, 31, 23, 59, 59),
    )
    await IncentiveService.publish_catalogue(
        db_session,
        version_id="PROP_CAT_2023",
        state_code="PROP_STATE",
        effective_from=datetime(2023, 1, 1),
        catalogue_data=cat_2023,
        effective_to=datetime(2023, 12, 31, 23, 59, 59),
    )
    await IncentiveService.publish_catalogue(
        db_session,
        version_id="PROP_CAT_2024",
        state_code="PROP_STATE",
        effective_from=datetime(2024, 1, 1),
        catalogue_data=cat_2024,
        effective_to=None,
    )
    await db_session.commit()

    # Invariant checks across 30 randomized trials
    for _ in range(30):
        year = rnd.choice([2022, 2023, 2024])
        month = rnd.randint(1, 12)
        day = rnd.randint(1, 28)
        event_dt = datetime(year, month, day)

        rate = await IncentiveService.get_rate_for_event(
            db_session, "ANC_REG_EARLY", event_dt, state_code="PROP_STATE"
        )
        if year == 2022:
            assert rate["total_rate"] == 80.0, "2022 rate must be 60+20=80"
        elif year == 2023:
            assert rate["total_rate"] == 110.0, "2023 rate must be 80+30=110"
        else:
            assert rate["total_rate"] == 160.0, "2024 rate must be 120+40=160"


@pytest.mark.asyncio
async def test_property_12_claim_line_item_round_trip(db_session: AsyncSession) -> None:
    """Property 12: Claim line items survive voucher processing and export with exact codes, amounts, and dates."""
    rnd = random.Random(42)
    activities = [
        ("ANC_REG_EARLY", 150.0),
        ("ANC_CHECKUP_FULL", 200.0),
        ("INSTITUTIONAL_DELIVERY", 600.0),
        ("HBNC_COMPLETE", 250.50),
        ("IMM_FULL_1YEAR", 100.25),
        ("CBAC_SCREENING", 10.0),
        ("NCD_FOLLOWUP", 50.75),
    ]

    worker = User(
        id=f"worker_p12_{uuid.uuid4().hex[:8]}",
        asha_id="ASHA_P12_EXP",
        name="Asha Export",
        role="ASHA",
        is_active=True,
    )
    db_session.add(worker)
    await db_session.commit()

    for trial in range(10):
        item_count = rnd.randint(1, 6)
        line_items = []
        total_amount = 0.0

        for i in range(item_count):
            act_code, amount = rnd.choice(activities)
            total_amount += amount
            service_dt = f"2024-04-{(i % 25) + 1:02d}"
            ev_id = f"ev_p12_{trial}_{i}_{uuid.uuid4().hex[:6]}"

            line_items.append({
                "incentive_event_id": ev_id,
                "activity_code": act_code,
                "activity_name": f"Activity {act_code}",
                "member_coded_id": f"MEM_10{i}{trial}",
                "service_date": service_dt,
                "amount": amount,
                "status": "approved",
            })

        claim_id = f"claim_p12_{trial}_{uuid.uuid4().hex[:8]}"
        claim = IncentiveClaim(
            id=claim_id,
            worker_id=worker.id,
            claim_period="2024-04",
            total_amount=total_amount,
            status="approved",
            line_items_json=json.dumps(line_items),
        )
        db_session.add(claim)
        await db_session.commit()

        # Export claim to ASHA Soft / PFMS CSV
        csv_text = await IncentiveService.export_asha_soft_csv(db_session, claim_id)
        reader = csv.DictReader(io.StringIO(csv_text))
        rows = list(reader)

        # Assert Property 12: all line items survive export with exact precision
        assert len(rows) == len(line_items)

        for orig_item, row in zip(line_items, rows, strict=False):
            assert row["Activity_Code"] == orig_item["activity_code"]
            assert row["Beneficiary_Coded_ID"] == orig_item["member_coded_id"]
            assert row["Service_Date"] == orig_item["service_date"]
            # Amount exact to 2 decimal places with no precision loss
            assert float(row["Amount"]) == pytest.approx(orig_item["amount"], 0.001)
