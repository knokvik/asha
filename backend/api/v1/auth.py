"""Auth API router — Task 2.2.

Endpoints:
    POST /api/v1/auth/login   — ASHA ID + PIN/OTP + device_id → tokens
    POST /api/v1/auth/refresh — Rotate access token using refresh token
    POST /api/v1/auth/revoke  — Admin: revoke all tokens for a worker
"""
from __future__ import annotations

import hashlib
import secrets
import time

from fastapi import APIRouter, Depends, Header, HTTPException, status
import httpx
from jose import JWTError
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from core.config import get_settings
from core.security import (
    create_offline_credential_hash,
    create_token,
    decode_token,
    hash_password,
    verify_password,
)
from db.session import get_db
from models.db.models import User
from models.schemas.schemas import (
    LoginRequest,
    PasswordResetRequest,
    PasswordResetConfirmRequest,
    PasswordResetResponse,
    RefreshRequest,
    RevokeRequest,
    SupabaseExchangeRequest,
    TokenResponse,
)

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
    normalized_phone = "".join(character for character in identifier if character.isdigit())
    phone_values = {normalized_phone, normalized_phone[-10:]}
    stmt = select(User).where(
        (func.lower(User.asha_id) == identifier.lower())
        | (func.lower(User.email) == identifier.lower())
        | User.phone.in_(phone_values)
    )
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


async def _supabase_identity(token: str) -> dict | None:
    """Confirm the bearer with Supabase Auth. A bad token returns None."""
    settings = get_settings()
    base = settings.SUPABASE_URL.strip().rstrip("/")
    if not base or not token:
        return None
    apikey = settings.SUPABASE_ANON_KEY.strip() or token
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.get(
                f"{base}/auth/v1/user",
                headers={
                    "Authorization": f"Bearer {token}",
                    "apikey": apikey,
                },
            )
    except httpx.HTTPError:
        return None
    if response.status_code != 200:
        return None
    try:
        payload = response.json()
    except ValueError:
        return None
    if not isinstance(payload, dict) or not payload.get("id"):
        return None
    return payload


def _tokens_for(user: User, *, device_id: str, pin: str) -> TokenResponse:
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
    settings = get_settings()
    now_epoch = int(time.time())
    offline_expires = now_epoch + settings.OFFLINE_CREDENTIAL_EXPIRE_DAYS * 86400
    offline_hash = create_offline_credential_hash(
        worker_id=user.id,
        device_id=device_id,
        pin=pin,
        expires_at=offline_expires,
    )
    user.offline_credential_hash = offline_hash
    user.offline_cred_expires_at = offline_expires
    user.jwt_refresh_token = refresh_token
    user.last_jwt_refresh_at = now_epoch
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        offline_credential_hash=offline_hash,
        offline_cred_expires_at=offline_expires,
        worker_id=user.id,
        role=user.role,
        name=user.name,
    )


@router.post("/supabase", response_model=TokenResponse, status_code=status.HTTP_200_OK)
async def exchange_supabase_session(
    body: SupabaseExchangeRequest,
    authorization: str = Header(...),
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    """Mint an API JWT for a worker who already signed in with Supabase.

    Sync rejects the Supabase session token. This checks that token with
    Supabase, then returns the access and refresh tokens the sync client uses.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing Bearer token")
    identity = await _supabase_identity(authorization.removeprefix("Bearer ").strip())
    if identity is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Supabase session could not be confirmed.",
        )

    supabase_id = str(identity["id"])[:36]
    email = identity.get("email")
    email = email.strip().lower() if isinstance(email, str) and email.strip() else None
    meta = identity.get("user_metadata") if isinstance(identity.get("user_metadata"), dict) else {}
    name = meta.get("name") or meta.get("full_name") or email or "ASHA worker"
    if not isinstance(name, str) or not name.strip():
        name = "ASHA worker"

    user = await _get_user_by_id(db, supabase_id)
    if user is None and email:
        found = await db.execute(select(User).where(func.lower(User.email) == email))
        user = found.scalar_one_or_none()
    if user is None:
        user = User(
            id=supabase_id,
            asha_id=supabase_id,
            name=name.strip()[:255],
            email=email,
            role="ASHA",
            is_active=True,
        )
        db.add(user)
        await db.flush()
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or inactive")

    tokens = _tokens_for(user, device_id=body.device_id, pin="supabase-session")
    await db.commit()
    return tokens


def _hash_reset_code(code: str) -> str:
    return hashlib.sha256(code.encode("utf-8")).hexdigest()


@router.post(
    "/password-reset/request",
    response_model=PasswordResetResponse,
    status_code=status.HTTP_202_ACCEPTED,
)
async def request_password_reset(
    body: PasswordResetRequest,
    db: AsyncSession = Depends(get_db),
) -> PasswordResetResponse:
    """Send a short-lived reset code without revealing whether an account exists."""
    identifier = body.identifier.strip()
    normalized_phone = "".join(character for character in identifier if character.isdigit())
    phone_values = {normalized_phone, normalized_phone[-10:]}
    result = await db.execute(
        select(User).where(
            (func.lower(User.asha_id) == identifier.lower())
            | (func.lower(User.email) == identifier.lower())
            | User.phone.in_(phone_values)
        )
    )
    user = result.scalar_one_or_none()
    generic_message = "If the account exists, a reset code has been sent to its registered email."
    if user is None or not user.is_active or not user.email:
        return PasswordResetResponse(message=generic_message)

    settings = get_settings()
    code = f"{secrets.randbelow(1_000_000):06d}"
    user.password_reset_token_hash = _hash_reset_code(code)
    user.password_reset_expires_at = int(time.time()) + 600
    await db.commit()

    if not settings.RESEND_API_KEY:
        # Do not expose the code to clients. Deployment must configure Resend.
        return PasswordResetResponse(message=generic_message)

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.post(
                "https://api.resend.com/emails",
                headers={"Authorization": f"Bearer {settings.RESEND_API_KEY}"},
                json={
                    "from": settings.RESEND_FROM_EMAIL,
                    "to": [user.email],
                    "subject": "ASHA Setu password reset code",
                    "html": (
                        f"<p>Your ASHA Setu reset code is <strong>{code}</strong>.</p>"
                        "<p>It expires in 10 minutes. If you did not request this, ignore this email.</p>"
                    ),
                },
            )
            response.raise_for_status()
    except httpx.HTTPError:
        # Keep the response generic and avoid leaking provider details.
        return PasswordResetResponse(message=generic_message)
    return PasswordResetResponse(message=generic_message)


@router.post("/password-reset/confirm", response_model=PasswordResetResponse)
async def confirm_password_reset(
    body: PasswordResetConfirmRequest,
    db: AsyncSession = Depends(get_db),
) -> PasswordResetResponse:
    """Apply a reset code sent by the backend provider to the server credential."""
    identifier = body.identifier.strip()
    normalized_phone = "".join(character for character in identifier if character.isdigit())
    result = await db.execute(
        select(User).where(
            (func.lower(User.asha_id) == identifier.lower())
            | (func.lower(User.email) == identifier.lower())
            | User.phone.in_({normalized_phone, normalized_phone[-10:]})
        )
    )
    user = result.scalar_one_or_none()
    valid = (
        user is not None
        and user.is_active
        and user.password_reset_token_hash == _hash_reset_code(body.code)
        and (user.password_reset_expires_at or 0) >= int(time.time())
    )
    if not valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The reset code is invalid or expired.",
        )
    user.hashed_pin = hash_password(body.new_password)
    user.password_reset_token_hash = None
    user.password_reset_expires_at = None
    user.jwt_refresh_token = None
    await db.commit()
    return PasswordResetResponse(message="Password reset successfully. Sign in with the new credential.")


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
