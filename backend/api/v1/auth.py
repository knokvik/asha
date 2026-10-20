"""Auth API router — Task 2.2.

Endpoints:
    POST /api/v1/auth/login   — ASHA ID + PIN/OTP + device_id → tokens
    POST /api/v1/auth/refresh — Rotate access token using refresh token
    POST /api/v1/auth/revoke  — Admin: revoke all tokens for a worker
"""
from __future__ import annotations

import time

from fastapi import APIRouter, Depends, Header, HTTPException, status
from jose import JWTError
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from core.security import (
    create_offline_credential_hash,
    create_token,
    decode_token,
    verify_password,
)
from db.session import get_db
from models.db.models import User
from models.schemas.schemas import LoginRequest, RefreshRequest, RevokeRequest, TokenResponse

router = APIRouter(prefix="/auth", tags=["auth"])

_ADMIN_ROLES = {"ADMIN", "STATE_ADMIN", "State_Admin"}


async def _require_admin(authorization: str = Header(...)) -> dict:
    """Require a valid access token issued to a State Administrator."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing Bearer token")
    try:
        payload = decode_token(authorization.removeprefix("Bearer "))
    except JWTError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token") from exc
    if payload.get("type") != "access" or payload.get("role") not in _ADMIN_ROLES:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="State administrator role required")
    return payload


async def _get_user_by_asha_id(db: AsyncSession, asha_id: str) -> User | None:
    result = await db.execute(select(User).where(User.asha_id == asha_id))
    return result.scalar_one_or_none()


async def _get_user_by_id(db: AsyncSession, user_id: str) -> User | None:
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()


@router.post("/login", response_model=TokenResponse, status_code=status.HTTP_200_OK)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    """Authenticate a worker or dashboard user and return real JWT access + refresh tokens."""
    identifier = (body.username or body.asha_id or "").strip()
    secret = body.password or body.pin

    _unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid credentials. Please verify your username/ID and password/PIN.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if not identifier or not secret:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username (or asha_id) and password (or pin) required.",
        )

    # Lookup user by asha_id or username (case-insensitive)
    stmt = select(User).where(func.lower(User.asha_id) == identifier.lower())
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if user is None or not user.is_active:
        raise _unauthorized

    # ── Lockout check ─────────────────────────────────────────────────────────
    now_epoch = int(time.time())
    if user.lockout_until and user.lockout_until > now_epoch:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Account locked until {user.lockout_until}",
        )

    # ── PIN / Password verification ───────────────────────────────────────────
    if not user.hashed_pin or not verify_password(secret, user.hashed_pin):
        user.failed_pin_attempts = (user.failed_pin_attempts or 0) + 1
        # Exponential lockout: 30s, 60s, 120s, 300s max
        backoff = min(30 * (2 ** (user.failed_pin_attempts - 1)), 300)
        user.lockout_until = now_epoch + backoff
        await db.commit()
        raise _unauthorized

    # ── Success — reset counters ───────────────────────────────────────────────
    user.failed_pin_attempts = 0
    user.lockout_until = None

    area_villages: list[str] = []
    if user.area_village:
        area_villages = [v.strip() for v in user.area_village.split(",") if v.strip()]

    access_token = create_token(
        sub=user.id,
        role=user.role,
        state_code=user.state_code or "",
        district_code=user.district_code or "",
        block_code=user.area_block or "",
        area_villages=area_villages,
        token_type="access",
    )
    refresh_token = create_token(
        sub=user.id,
        role=user.role,
        state_code=user.state_code or "",
        district_code=user.district_code or "",
        block_code=user.area_block or "",
        area_villages=area_villages,
        token_type="refresh",
    )

    # ── Offline credential (7-day, device-bound) ──────────────────────────────
    from core.config import get_settings  # local import avoids circular

    settings = get_settings()
    offline_expires = now_epoch + settings.OFFLINE_CREDENTIAL_EXPIRE_DAYS * 86400
    offline_hash = create_offline_credential_hash(
        worker_id=user.id,
        device_id=body.device_id,
        pin=body.pin,
        expires_at=offline_expires,
    )

    user.offline_credential_hash = offline_hash
    user.offline_cred_expires_at = offline_expires
    user.jwt_refresh_token = refresh_token
    user.last_jwt_refresh_at = now_epoch
    await db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        offline_credential_hash=offline_hash,
        offline_cred_expires_at=offline_expires,
        worker_id=user.id,
        role=user.role,
        name=user.name,
    )


@router.get("/me", status_code=status.HTTP_200_OK)
async def get_current_user(
    authorization: str = Header(...),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Return the profile and role metadata of the authenticated user from the database."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing Bearer token")
    token = authorization.removeprefix("Bearer ")
    try:
        payload = decode_token(token)
    except JWTError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token") from exc

    user = await _get_user_by_id(db, payload.get("sub", ""))
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or inactive")

    return {
        "id": user.id,
        "username": user.asha_id,
        "name": user.name,
        "role": user.role,
        "facility": user.area_phc or user.area_subcentre or "District Health Command",
        "designation": user.role,
        "stateCode": user.state_code or "UP",
        "districtCode": user.district_code or "DIST_01",
        "blockCode": user.block_code or "BLK_01",
        "subcentreId": user.area_subcentre,
        "phcId": user.area_phc,
    }


@router.post("/refresh", response_model=TokenResponse, status_code=status.HTTP_200_OK)
async def refresh(body: RefreshRequest, db: AsyncSession = Depends(get_db)) -> TokenResponse:
    """Rotate an access token using a valid refresh token.

    Requirements: 2.1, 2.6
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate refresh token",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_token(body.refresh_token)
    except JWTError:
        raise credentials_exception

    if payload.get("type") != "refresh":
        raise credentials_exception

    user = await _get_user_by_id(db, payload["sub"])
    if user is None or not user.is_active:
        raise credentials_exception

    # Verify stored refresh token matches (prevents reuse after revoke)
    if user.jwt_refresh_token != body.refresh_token:
        raise credentials_exception

    area_villages: list[str] = payload.get("area_villages", [])
    new_access = create_token(
        sub=user.id,
        role=user.role,
        state_code=payload.get("state_code", ""),
        district_code=payload.get("district_code", ""),
        block_code=payload.get("block_code", ""),
        area_villages=area_villages,
        token_type="access",
    )

    return TokenResponse(
        access_token=new_access,
        refresh_token=body.refresh_token,  # Reuse same refresh token
        offline_credential_hash=user.offline_credential_hash or "",
        offline_cred_expires_at=user.offline_cred_expires_at or 0,
        worker_id=user.id,
        role=user.role,
        name=user.name,
    )


@router.post("/revoke", status_code=status.HTTP_204_NO_CONTENT, response_model=None)
async def revoke(
    body: RevokeRequest,
    _: dict = Depends(_require_admin),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Admin: revoke all tokens for a worker (lost device, reassignment).

    Clears refresh token and offline credential; forces re-authentication.
    Requirements: 2.5
    """
    user = await _get_user_by_id(db, body.worker_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Worker not found")

    user.jwt_refresh_token = None
    user.offline_credential_hash = None
    user.offline_cred_expires_at = None
    await db.commit()
