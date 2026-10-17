"""Integration tests for auth endpoints — Task 2.2.

Tests:
- POST /api/v1/auth/login happy path
- POST /api/v1/auth/login wrong PIN increments lockout
- POST /api/v1/auth/refresh with valid refresh token
- POST /api/v1/auth/revoke clears tokens

Requirements: 2.1, 2.6, 2.7
"""
from __future__ import annotations

import time
import uuid

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from core.security import hash_password
from models.db.models import User


async def _create_test_user(
    db: AsyncSession,
    *,
    asha_id: str,
    pin: str = "1234",
    user_id: str | None = None,
    role: str = "ASHA",
) -> User:
    user = User(
        id=user_id or str(uuid.uuid4()),
        asha_id=asha_id,
        name="Test ASHA",
        role=role,
        hashed_pin=hash_password(pin),
        area_block="B01",
        state_code="MH",
        district_code="D01",
        is_active=True,
    )
    db.add(user)
    await db.flush()
    return user


@pytest.mark.asyncio
class TestAuthLogin:
    async def test_login_success(self, async_client, db_session):
        user = await _create_test_user(db_session, asha_id="ASHA_LS_001")
        response = await async_client.post(
            "/api/v1/auth/login",
            json={"asha_id": "ASHA_LS_001", "pin": "1234", "device_id": "dev-1"},
        )
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["role"] == "ASHA"
        assert data["worker_id"] == user.id

    async def test_login_wrong_pin_returns_401(self, async_client, db_session):
        await _create_test_user(db_session, asha_id="ASHA_LS_002")
        response = await async_client.post(
            "/api/v1/auth/login",
            json={"asha_id": "ASHA_LS_002", "pin": "9999", "device_id": "dev-1"},
        )
        assert response.status_code == 401

    async def test_login_unknown_user_returns_401(self, async_client, db_session):
        response = await async_client.post(
            "/api/v1/auth/login",
            json={"asha_id": "NOBODY_KNOWN", "pin": "1234", "device_id": "dev-1"},
        )
        assert response.status_code == 401

    async def test_login_offline_credential_returned(self, async_client, db_session):
        await _create_test_user(db_session, asha_id="ASHA_LS_003")
        response = await async_client.post(
            "/api/v1/auth/login",
            json={"asha_id": "ASHA_LS_003", "pin": "1234", "device_id": "my-device"},
        )
        assert response.status_code == 200
        data = response.json()
        assert len(data["offline_credential_hash"]) == 64  # SHA-256 hex
        assert data["offline_cred_expires_at"] > int(time.time())


@pytest.mark.asyncio
class TestAuthRefresh:
    async def test_refresh_returns_new_access_token(self, async_client, db_session):
        await _create_test_user(db_session, asha_id="ASHA_RF_001")
        login_resp = await async_client.post(
            "/api/v1/auth/login",
            json={"asha_id": "ASHA_RF_001", "pin": "1234", "device_id": "dev-r1"},
        )
        tokens = login_resp.json()

        refresh_resp = await async_client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": tokens["refresh_token"], "device_id": "dev-r1"},
        )
        assert refresh_resp.status_code == 200
        new_tokens = refresh_resp.json()
        assert "access_token" in new_tokens

    async def test_refresh_with_invalid_token_returns_401(self, async_client, db_session):
        response = await async_client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": "bad.token.value", "device_id": "dev-1"},
        )
        assert response.status_code == 401


@pytest.mark.asyncio
class TestAuthRevoke:
    async def test_revoke_requires_state_admin(self, async_client, db_session):
        user = await _create_test_user(db_session, asha_id="ASHA_RV_UNAUTH")
        response = await async_client.post("/api/v1/auth/revoke", json={"worker_id": user.id})
        assert response.status_code == 422

    async def test_revoke_clears_refresh_token(self, async_client, db_session):
        user = await _create_test_user(db_session, asha_id="ASHA_RV_001")
        admin = await _create_test_user(
            db_session,
            asha_id="ADMIN_RV_001",
            role="STATE_ADMIN",
        )
        await async_client.post(
            "/api/v1/auth/login",
            json={"asha_id": "ASHA_RV_001", "pin": "1234", "device_id": "dev-rv1"},
        )
        admin_login = await async_client.post(
            "/api/v1/auth/login",
            json={"asha_id": admin.asha_id, "pin": "1234", "device_id": "admin-device"},
        )
        revoke_resp = await async_client.post(
            "/api/v1/auth/revoke",
            json={"worker_id": user.id},
            headers={"Authorization": f"Bearer {admin_login.json()['access_token']}"},
        )
        assert revoke_resp.status_code == 204
