"""Unit tests for security utilities.

Tests:
- hash_password / verify_password round-trip
- create_token / decode_token round-trip
- offline credential creation and verification
- expired credential returns False

Requirements: 2.1, 2.6, 44.1
"""
from __future__ import annotations

import time

import pytest

from core.security import (
    create_offline_credential_hash,
    create_token,
    decode_token,
    hash_password,
    verify_password,
    verify_offline_credential,
)


class TestPasswordHashing:
    def test_hash_and_verify_roundtrip(self):
        hashed = hash_password("1234")
        assert verify_password("1234", hashed) is True

    def test_wrong_password_returns_false(self):
        hashed = hash_password("1234")
        assert verify_password("9999", hashed) is False

    def test_different_pins_produce_different_hashes(self):
        assert hash_password("1111") != hash_password("2222")


class TestJWT:
    _common = dict(
        sub="worker-123",
        role="ASHA",
        state_code="MH",
        district_code="D01",
        block_code="B01",
        area_villages=["V01", "V02"],
    )

    def test_access_token_roundtrip(self):
        token = create_token(**self._common, token_type="access")
        payload = decode_token(token)
        assert payload["sub"] == "worker-123"
        assert payload["role"] == "ASHA"
        assert payload["type"] == "access"
        assert payload["block_code"] == "B01"
        assert payload["area_villages"] == ["V01", "V02"]

    def test_refresh_token_type(self):
        token = create_token(**self._common, token_type="refresh")
        payload = decode_token(token)
        assert payload["type"] == "refresh"

    def test_invalid_token_raises(self):
        from jose import JWTError

        with pytest.raises(JWTError):
            decode_token("not.a.valid.token")


class TestOfflineCredential:
    _args = dict(
        worker_id="w1",
        device_id="dev1",
        pin="4321",
        expires_at=int(time.time()) + 86400 * 7,
    )

    def test_valid_credential_returns_true(self):
        h = create_offline_credential_hash(**self._args)
        assert verify_offline_credential(**self._args, stored_hash=h) is True

    def test_wrong_pin_returns_false(self):
        h = create_offline_credential_hash(**self._args)
        assert verify_offline_credential(
            worker_id="w1", device_id="dev1", pin="0000",
            expires_at=self._args["expires_at"], stored_hash=h,
        ) is False

    def test_expired_credential_returns_false(self):
        expired_at = int(time.time()) - 1
        h = create_offline_credential_hash(
            worker_id="w1", device_id="dev1", pin="4321", expires_at=expired_at
        )
        assert verify_offline_credential(
            worker_id="w1", device_id="dev1", pin="4321",
            expires_at=expired_at, stored_hash=h,
        ) is False

    def test_wrong_device_returns_false(self):
        h = create_offline_credential_hash(**self._args)
        assert verify_offline_credential(
            worker_id="w1", device_id="other-device", pin="4321",
            expires_at=self._args["expires_at"], stored_hash=h,
        ) is False
