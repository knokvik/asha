"""Integration tests for sync push/pull endpoints — Tasks 2.4, 2.5, 2.10, 2.11.

Tests:
- POST /api/v1/sync/push — single record insert
- POST /api/v1/sync/push — same batch_id twice (idempotency)
- POST /api/v1/sync/push — gzip-compressed body
- GET  /api/v1/sync/pull — watermark-based delta delivery
- Property: pushing same batch twice produces identical DB state (Property 6)

Requirements: 31.1, 31.2, 32.2, 32.3
"""
from __future__ import annotations

import base64
import gzip
import json
import time
import uuid

import pytest

from core.security import create_token
import services.sync_service as sync_svc_module


def _auth_header(user_id: str = "worker-sync-1") -> dict[str, str]:
    token = create_token(
        sub=user_id,
        role="ASHA",
        state_code="MH",
        district_code="D01",
        block_code="B01",
        area_villages=["V01"],
        token_type="access",
    )
    return {"Authorization": f"Bearer {token}"}


def _push_payload(
    batch_id: str | None = None,
    record_id: str | None = None,
    worker_id: str = "worker-sync-1",
) -> dict:
    return {
        "device_id": "dev-sync-1",
        "worker_id": worker_id,
        "app_version": "1.0.0",
        "batch_id": batch_id or str(uuid.uuid4()),
        "sent_at": int(time.time() * 1000),
        "records": [
            {
                "table": "households",
                "record_id": record_id or str(uuid.uuid4()),
                "operation": "insert",
                "priority": 2,
                "payload": {
                    "village": "TestVillage",
                    "head_name": "Ram Lal",
                    "member_count": 4,
                },
                "event_log": [],
                "device_timestamp": int(time.time() * 1000),
                "client_watermark": 0,
            }
        ],
    }


@pytest.fixture(autouse=True)
def clear_processed_batches():
    """Clear the in-memory idempotency set before each test."""
    sync_svc_module._GLOBAL_PROCESSED_BATCHES.clear()
    yield
    sync_svc_module._GLOBAL_PROCESSED_BATCHES.clear()


@pytest.mark.asyncio
class TestSyncPush:
    async def test_push_single_record_returns_synced(self, async_client, db_session):
        payload = _push_payload()
        resp = await async_client.post(
            "/api/v1/sync/push",
            json=payload,
            headers=_auth_header(),
        )
        assert resp.status_code == 200
        data = resp.json()
        assert len(data["synced"]) == 1
        assert data["synced"][0] == payload["records"][0]["record_id"]
        assert data["conflicts"] == []

    async def test_push_same_batch_twice_is_idempotent(self, async_client, db_session):
        """Property 6: applying same batch twice leaves DB state unchanged."""
        batch_id = str(uuid.uuid4())
        record_id = str(uuid.uuid4())
        payload = _push_payload(batch_id=batch_id, record_id=record_id)

        resp1 = await async_client.post("/api/v1/sync/push", json=payload, headers=_auth_header())
        resp2 = await async_client.post("/api/v1/sync/push", json=payload, headers=_auth_header())

        assert resp1.status_code == 200
        assert resp2.status_code == 200
        # Second push should return empty synced list (duplicate detected)
        data2 = resp2.json()
        assert data2["synced"] == []

    async def test_push_gzip_compressed_body(self, async_client, db_session):
        payload = _push_payload()
        body = gzip.compress(json.dumps(payload).encode())
        resp = await async_client.post(
            "/api/v1/sync/push",
            content=body,
            headers={**_auth_header(), "Content-Encoding": "gzip", "Content-Type": "application/json"},
        )
        assert resp.status_code == 200
        assert len(resp.json()["synced"]) == 1

    async def test_push_without_auth_returns_422(self, async_client, db_session):
        """Missing Authorization header → 422 (Header required)."""
        payload = _push_payload()
        resp = await async_client.post("/api/v1/sync/push", json=payload)
        assert resp.status_code == 422

    async def test_triage_evidence_is_listed_and_served_to_authenticated_dashboard(
        self, async_client, db_session
    ):
        record_id = "CASE-EVIDENCE-1"
        attachment = {
            "type": "image",
            "mime_type": "image/jpeg",
            "encoding": "gzip+base64",
            "original_bytes": 11,
            "compressed_bytes": 31,
            "data_base64": base64.b64encode(gzip.compress(b"photo-bytes")).decode(),
        }
        payload = _push_payload(record_id=record_id)
        payload["records"][0] = {
            "table": "triage_tickets",
            "record_id": record_id,
            "operation": "insert",
            "priority": 1,
            "payload": {
                "name": "Asha Test Patient",
                "location": "Rampur",
                "flag": "RED",
                "ward_id": "W3",
                "attachments_json": json.dumps([attachment]),
            },
            "event_log": [],
            "device_timestamp": int(time.time() * 1000),
            "client_watermark": 0,
        }
        pushed = await async_client.post(
            "/api/v1/sync/push", json=payload, headers=_auth_header()
        )
        assert pushed.status_code == 200

        activity = await async_client.get(
            "/api/v1/sync/activity", headers=_auth_header()
        )
        assert activity.status_code == 200
        packet = next(item for item in activity.json()["packets"] if item["record_id"] == record_id)
        assert packet["ticket"]["patient_name"] == "Asha Test Patient"
        assert packet["ticket"]["attachments"] == [
            {
                "index": 0,
                "type": "image",
                "mime_type": "image/jpeg",
                "original_bytes": 11,
                "url": f"/sync/triage-tickets/{record_id}/attachments/0",
            }
        ]

        evidence = await async_client.get(
            f"/api/v1/sync/triage-tickets/{record_id}/attachments/0",
            headers=_auth_header(),
        )
        assert evidence.status_code == 200
        assert evidence.headers["content-type"].startswith("image/jpeg")
        assert evidence.content == b"photo-bytes"

        forbidden = await async_client.get(
            f"/api/v1/sync/triage-tickets/{record_id}/attachments/0",
            headers=_auth_header("another-worker"),
        )
        assert forbidden.status_code == 403

    async def test_hotspots_require_two_workers_and_return_aggregate_context(
        self, async_client, db_session
    ):
        """Cross-worker reports become an area signal without exposing patients."""
        for index, worker_id in enumerate(
            ("worker-sync-1", "worker-sync-2", "worker-sync-1")
        ):
            payload = _push_payload(worker_id=worker_id)
            payload["records"][0] = {
                "table": "triage_tickets",
                "record_id": f"CASE-HOTSPOT-{index}",
                "operation": "insert",
                "priority": 2,
                "payload": {
                    "name": "Should not be returned",
                    "location": "Ward W3",
                    "ward_id": "W3",
                    "modules_json": json.dumps(["dengue"]),
                    "created_at": int(time.time() * 1000),
                },
                "event_log": [],
                "device_timestamp": int(time.time() * 1000),
                "client_watermark": 0,
            }
            pushed = await async_client.post(
                "/api/v1/sync/push", json=payload, headers=_auth_header(worker_id)
            )
            assert pushed.status_code == 200

        response = await async_client.get("/api/v1/sync/hotspots", headers=_auth_header())
        assert response.status_code == 200
        data = response.json()
        active = next(item for item in data["hotspots"] if item["ward_id"] == "W3")
        assert active["module_id"] == "dengue"
        assert active["worker_count"] == 2
        assert active["active"] is True
        assert data["notifications"]
        assert data["notifications"][0]["ward_id"] == "W3"
        assert data["counts"][0]["condition"] == "dengue_like"
        assert "Should not be returned" not in json.dumps(data)


@pytest.mark.asyncio
class TestSyncPull:
    async def test_pull_without_watermarks_returns_records(self, async_client, db_session):
        # First push a record so there's something to pull
        push_payload = _push_payload()
        await async_client.post("/api/v1/sync/push", json=push_payload, headers=_auth_header())

        resp = await async_client.get(
            "/api/v1/sync/pull",
            params={"worker_id": "worker-sync-1", "watermarks": "{}"},
            headers=_auth_header(),
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "records" in data
        assert "server_watermarks" in data
        assert isinstance(data["has_more"], bool)

    async def test_pull_worker_id_mismatch_returns_403(self, async_client, db_session):
        resp = await async_client.get(
            "/api/v1/sync/pull",
            params={"worker_id": "other-worker", "watermarks": "{}"},
            headers=_auth_header("worker-sync-1"),
        )
        assert resp.status_code == 403

    async def test_pull_accepts_gzip_encoding(self, async_client, db_session):
        resp = await async_client.get(
            "/api/v1/sync/pull",
            params={"worker_id": "worker-sync-1", "watermarks": "{}"},
            headers={**_auth_header(), "Accept-Encoding": "gzip"},
        )
        assert resp.status_code == 200
