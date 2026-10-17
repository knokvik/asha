"""JWT, bcrypt, and rate-limiting utilities.

Security policy:
- Access tokens expire in 15 minutes.
- Refresh tokens expire in 30 days.
- Offline credentials expire in 7 days; stored as bcrypt hash on device.
- Payload fields: sub (worker_id), role, state_code, district_code, block_code,
  area_villages, exp, iat, type ('access' | 'refresh').
"""
from __future__ import annotations

import hashlib
import hmac
import time
from datetime import UTC, datetime, timedelta
from typing import Literal

import bcrypt as _bcrypt
from jose import jwt

from core.config import get_settings

_settings = get_settings()


# ── Password / PIN helpers ────────────────────────────────────────────────────


def hash_password(plain: str) -> str:
    """Return bcrypt hash of *plain* (PIN or password)."""
    return _bcrypt.hashpw(plain.encode(), _bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    """Return True if *plain* matches *hashed*."""
    return _bcrypt.checkpw(plain.encode(), hashed.encode())


# ── JWT helpers ───────────────────────────────────────────────────────────────

TokenType = Literal["access", "refresh"]


def _utcnow() -> datetime:
    return datetime.now(UTC)


def create_token(
    *,
    sub: str,
    role: str,
    state_code: str,
    district_code: str,
    block_code: str,
    area_villages: list[str],
    token_type: TokenType = "access",
) -> str:
    """Mint a signed JWT.

    Args:
        sub: worker_id (subject).
        role: e.g. 'ASHA', 'ASHA_FACILITATOR', 'ANM', 'PHC_MO', 'ADMIN'.
        token_type: 'access' (15 min) or 'refresh' (30 days).
    """
    settings = get_settings()
    if token_type == "access":
        expires_delta = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    else:
        expires_delta = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    now = _utcnow()
    payload = {
        "sub": sub,
        "role": role,
        "state_code": state_code,
        "district_code": district_code,
        "block_code": block_code,
        "area_villages": area_villages,
        "type": token_type,
        "iat": now,
        "exp": now + expires_delta,
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_token(token: str) -> dict:
    """Decode and validate a JWT; raises JWTError on failure."""
    settings = get_settings()
    return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])


# ── Offline credential ────────────────────────────────────────────────────────


def create_offline_credential_hash(
    *,
    worker_id: str,
    device_id: str,
    pin: str,
    expires_at: int,
) -> str:
    """Produce an HMAC-SHA256 offline credential stored on the device.

    The credential binds worker identity, device, PIN, and expiry so that
    it cannot be replayed on a different device or after expiry.
    """
    settings = get_settings()
    message = f"{worker_id}:{device_id}:{pin}:{expires_at}".encode()
    return hmac.new(settings.SECRET_KEY.encode(), message, hashlib.sha256).hexdigest()


def verify_offline_credential(
    *,
    worker_id: str,
    device_id: str,
    pin: str,
    expires_at: int,
    stored_hash: str,
) -> bool:
    """Return True if credential is valid and not expired."""
    if int(time.time()) > expires_at:
        return False
    expected = create_offline_credential_hash(
        worker_id=worker_id,
        device_id=device_id,
        pin=pin,
        expires_at=expires_at,
    )
    return hmac.compare_digest(expected, stored_hash)
