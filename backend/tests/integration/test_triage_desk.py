"""Prompt 2: ticket lifecycle, dedup, escalation, and pack bump."""
from __future__ import annotations

import gzip
import json
from datetime import datetime

import pytest

from core.security import create_token
from services.triage_desk import CountPoint, merge_counts

AUTH = {
    "Authorization": "Bearer "
    + create_token(
        sub="test-phc-user",
        role="PHC_MO",
        state_code="MH",
        district_code="TEST",
        block_code="TEST",
        area_villages=[],
    )
}


def _referral(key: str, referral_id: str, priority: str = "RED", created_at: str = "2026-10-19T08:00:00", ward: str = "W3") -> dict:
    return {
        "type": "referral",
        "idempotency_key": key,
        "payload": {
            "referral_id": referral_id,
            "priority": priority,
            "flag": priority,
            "ward_id": ward,
            "district_id": "PCMC",
            "asha_id": "ASHA-SUNITA",
            "created_at": created_at,
            "fired_rules": ["DS-CONV"],
        },
    }


@pytest.mark.asyncio
async def test_batch_opens_a_new_red_ticket(async_client):
    response = await async_client.post("/api/v1/sync/batch", headers=AUTH, json={"items": [_referral("k1", "CASE-1")]})
    assert response.status_code == 200
    body = response.json()
    assert body["accepted"][0]["duplicate"] is False
    ticket_id = body["accepted"][0]["ticket_id"]
    ticket = await async_client.get(f"/api/v1/tickets/{ticket_id}", headers=AUTH)
    assert ticket.json()["status"] == "NEW"
    assert ticket.json()["priority"] == "RED"
    assert ticket.json()["sla_due_at"] is not None


@pytest.mark.asyncio
async def test_same_idempotency_key_does_not_duplicate(async_client):
    item = _referral("same-key", "CASE-DUP")
    first = await async_client.post("/api/v1/sync/batch", headers=AUTH, json={"items": [item]})
    second = await async_client.post("/api/v1/sync/batch", headers=AUTH, json={"items": [item]})
    assert first.json()["accepted"][0]["ticket_id"] == second.json()["accepted"][0]["ticket_id"]
    assert second.json()["accepted"][0]["duplicate"] is True
    listed = await async_client.get("/api/v1/tickets", headers=AUTH)
    matches = [row for row in listed.json()["tickets"] if row["referral_id"] == "CASE-DUP"]
    assert len(matches) == 1


@pytest.mark.asyncio
async def test_ticket_reaches_closed(async_client):
    opened = await async_client.post("/api/v1/sync/batch", headers=AUTH, json={"items": [_referral("life", "CASE-LIFE")]})
    ticket_id = opened.json()["accepted"][0]["ticket_id"]
    ack = await async_client.post(f"/api/v1/tickets/{ticket_id}/ack", headers=AUTH)
    consult = await async_client.post(f"/api/v1/tickets/{ticket_id}/consult", headers=AUTH)
    outcome = await async_client.post(
        f"/api/v1/tickets/{ticket_id}/outcome",
        headers=AUTH,
        json={"diagnosis": "Very severe disease", "action": "referred_up", "note_for_asha": "Stay with the child."},
    )
    assert ack.json()["status"] == "ACKNOWLEDGED"
    assert consult.json()["status"] == "IN_CARE"
    assert outcome.json()["status"] == "CLOSED"


@pytest.mark.asyncio
async def test_consult_before_ack_is_rejected(async_client):
    opened = await async_client.post("/api/v1/sync/batch", headers=AUTH, json={"items": [_referral("early", "CASE-EARLY")]})
    ticket_id = opened.json()["accepted"][0]["ticket_id"]
    response = await async_client.post(f"/api/v1/tickets/{ticket_id}/consult", headers=AUTH)
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_outcome_requires_a_diagnosis(async_client):
    opened = await async_client.post("/api/v1/sync/batch", headers=AUTH, json={"items": [_referral("dx", "CASE-DX")]})
    ticket_id = opened.json()["accepted"][0]["ticket_id"]
    await async_client.post(f"/api/v1/tickets/{ticket_id}/ack", headers=AUTH)
    response = await async_client.post(
        f"/api/v1/tickets/{ticket_id}/outcome",
        headers=AUTH,
        json={"diagnosis": "  ", "action": "treated"},
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_outcome_rejects_an_unknown_action(async_client):
    opened = await async_client.post("/api/v1/sync/batch", headers=AUTH, json={"items": [_referral("act", "CASE-ACT")]})
    ticket_id = opened.json()["accepted"][0]["ticket_id"]
    await async_client.post(f"/api/v1/tickets/{ticket_id}/ack", headers=AUTH)
    response = await async_client.post(
        f"/api/v1/tickets/{ticket_id}/outcome",
        headers=AUTH,
        json={"diagnosis": "Pneumonia", "action": "admitted"},
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_red_ticket_escalates_after_four_hours(async_client):
    await async_client.post(
        "/api/v1/sync/batch",
        headers=AUTH,
        json={"items": [_referral("late", "CASE-LATE", created_at="2026-10-19T08:00:00")]},
    )
    response = await async_client.post("/api/v1/jobs/escalate", headers={**AUTH, "X-Now": "2026-10-19T13:00:00"})
    notices = response.json()["escalated"]
    assert len(notices) == 1
    assert "CASE-LATE" in notices[0]["body"]
    assert notices[0]["channel"] == "sms"


@pytest.mark.asyncio
async def test_acknowledged_red_does_not_escalate(async_client):
    opened = await async_client.post(
        "/api/v1/sync/batch",
        headers=AUTH,
        json={"items": [_referral("acked", "CASE-ACKED", created_at="2026-10-19T08:00:00")]},
    )
    ticket_id = opened.json()["accepted"][0]["ticket_id"]
    await async_client.post(f"/api/v1/tickets/{ticket_id}/ack", headers=AUTH)
    response = await async_client.post("/api/v1/jobs/escalate", headers={**AUTH, "X-Now": "2026-10-19T13:00:00"})
    assert response.json()["escalated"] == []


@pytest.mark.asyncio
async def test_yellow_ticket_does_not_escalate(async_client):
    await async_client.post(
        "/api/v1/sync/batch",
        headers=AUTH,
        json={"items": [_referral("yel", "CASE-YEL", priority="YELLOW", created_at="2026-10-19T08:00:00")]},
    )
    response = await async_client.post("/api/v1/jobs/escalate", headers={**AUTH, "X-Now": "2026-10-19T20:00:00"})
    assert response.json()["escalated"] == []


@pytest.mark.asyncio
async def test_queue_lists_oldest_red_first(async_client):
    await async_client.post(
        "/api/v1/sync/batch",
        headers=AUTH,
        json={
            "items": [
                _referral("new", "CASE-NEW", created_at="2026-10-19T10:00:00"),
                _referral("old", "CASE-OLD", created_at="2026-10-19T07:00:00"),
                _referral("y", "CASE-Y", priority="YELLOW", created_at="2026-10-19T06:00:00"),
            ]
        },
    )
    listed = await async_client.get("/api/v1/tickets?priority=RED", headers=AUTH)
    ids = [row["referral_id"] for row in listed.json()["tickets"]]
    assert ids.index("CASE-OLD") < ids.index("CASE-NEW")


@pytest.mark.asyncio
async def test_latest_pack_is_v2_and_honours_etag(async_client):
    first = await async_client.get("/api/v1/packs/latest?district_id=PCMC", headers=AUTH)
    assert first.status_code == 200
    assert first.json()["manifest"]["pack_version"] == 2
    assert first.json()["active_dengue_ward"] == "W5"
    etag = first.headers["etag"]
    second = await async_client.get("/api/v1/packs/latest?district_id=PCMC", headers={**AUTH, "If-None-Match": etag})
    assert second.status_code == 304


@pytest.mark.asyncio
async def test_heatmap_uses_the_newer_app_count(async_client):
    await async_client.post(
        "/api/v1/sync/batch",
        headers=AUTH,
        json={
            "items": [
                {
                    "type": "flag_count",
                    "idempotency_key": "idsp-w3",
                    "payload": {
                        "ward_id": "W3",
                        "week": 11,
                        "condition": "dengue_like",
                        "count": 5,
                        "source": "idsp",
                        "observed_at": "2026-10-01T00:00:00",
                    },
                },
                {
                    "type": "flag_count",
                    "idempotency_key": "app-w5",
                    "payload": {
                        "ward_id": "W5",
                        "week": 11,
                        "condition": "dengue_like",
                        "count": 4,
                        "observed_at": "2026-10-18T00:00:00",
                    },
                },
            ]
        },
    )
    heat = await async_client.get("/api/v1/analytics/heatmap?district_id=PCMC&week=11", headers=AUTH)
    wards = {row["ward_id"]: row["flags"] for row in heat.json()["wards"]}
    assert wards["W3"] == 5
    assert wards["W5"] == 4


@pytest.mark.asyncio
async def test_asha_stats_count_closed_referrals(async_client):
    opened = await async_client.post("/api/v1/sync/batch", headers=AUTH, json={"items": [_referral("stat", "CASE-STAT")]})
    ticket_id = opened.json()["accepted"][0]["ticket_id"]
    await async_client.post(f"/api/v1/tickets/{ticket_id}/ack", headers=AUTH)
    await async_client.post(
        f"/api/v1/tickets/{ticket_id}/outcome",
        headers=AUTH,
        json={"diagnosis": "Pneumonia", "action": "home", "note_for_asha": "Review in 2 days."},
    )
    stats = await async_client.get("/api/v1/ashas/ASHA-SUNITA/stats", headers=AUTH)
    assert stats.json()["cases"] >= 1
    assert stats.json()["red"] >= 1
    assert stats.json()["completion_pct"] == 100


@pytest.mark.asyncio
async def test_batch_over_fifty_is_rejected(async_client):
    items = [_referral(f"bulk-{index}", f"CASE-BULK-{index}") for index in range(51)]
    response = await async_client.post("/api/v1/sync/batch", headers=AUTH, json={"items": items})
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_gzip_batch_is_accepted(async_client):
    raw = gzip.compress(json.dumps({"items": [_referral("gz", "CASE-GZ")]}).encode())
    response = await async_client.post(
        "/api/v1/sync/batch",
        headers={**AUTH, "Content-Encoding": "gzip"},
        content=raw,
    )
    assert response.status_code == 200
    assert response.json()["accepted"][0]["duplicate"] is False


@pytest.mark.asyncio
async def test_missing_token_is_rejected(async_client):
    response = await async_client.get("/api/v1/tickets")
    assert response.status_code == 401


def test_newer_app_count_replaces_the_idsp_baseline():
    older = datetime(2026, 10, 1)
    newer = datetime(2026, 10, 18)
    merged = merge_counts(
        [
            CountPoint("W3", 11, "dengue_like", 5, "idsp", older),
            CountPoint("W3", 11, "dengue_like", 1, "app", newer),
        ]
    )
    assert len(merged) == 1
    assert merged[0].count == 1
    assert merged[0].source == "app"


def test_older_app_count_does_not_replace_a_newer_baseline():
    merged = merge_counts(
        [
            CountPoint("W5", 11, "dengue_like", 5, "idsp", datetime(2026, 10, 18)),
            CountPoint("W5", 11, "dengue_like", 9, "app", datetime(2026, 10, 1)),
        ]
    )
    assert merged[0].count == 5
    assert merged[0].source == "idsp"


def test_equal_timestamps_prefer_the_app_report():
    stamp = datetime(2026, 10, 18)
    merged = merge_counts(
        [
            CountPoint("W3", 11, "dengue_like", 2, "idsp", stamp),
            CountPoint("W3", 11, "dengue_like", 6, "app", stamp),
        ]
    )
    assert merged[0].source == "app"
    assert merged[0].count == 6
