"""Pydantic schemas for auth, sync, and common types."""
from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


# ── Auth schemas ──────────────────────────────────────────────────────────────


class LoginRequest(BaseModel):
    asha_id: str | None = Field(None, description="ASHA worker ID")
    username: str | None = Field(None, description="Username for web login")
    pin: str | None = Field(None, min_length=4, max_length=50, description="PIN or password")
    password: str | None = Field(None, min_length=4, max_length=50, description="Password for web login")
    device_id: str = Field(default="web-dashboard", description="Unique device identifier")
    otp: str | None = Field(None, description="OTP for account recovery")


class PasswordResetRequest(BaseModel):
    identifier: str = Field(..., min_length=3, max_length=320)


class PasswordResetConfirmRequest(BaseModel):
    identifier: str = Field(..., min_length=3, max_length=320)
    code: str = Field(..., min_length=6, max_length=6)
    new_password: str = Field(..., min_length=4, max_length=50)


class PasswordResetResponse(BaseModel):
    message: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    offline_credential_hash: str
    offline_cred_expires_at: int
    token_type: str = "bearer"
    worker_id: str
    role: str
    name: str


class RefreshRequest(BaseModel):
    refresh_token: str
    device_id: str


class SupabaseExchangeRequest(BaseModel):
    device_id: str = Field(default="mobile", min_length=1, max_length=128)


class RevokeRequest(BaseModel):
    worker_id: str
    reason: str | None = Field(None, min_length=1, max_length=500)


# ── Sync schemas ──────────────────────────────────────────────────────────────


class EventLogEntry(BaseModel):
    field: str
    old_value: Any = None
    new_value: Any = None
    changed_by: str
    device_id: str
    device_timestamp: int
    chain_hash: str | None = None


class SyncRecord(BaseModel):
    table: str
    record_id: str
    operation: Literal["insert", "update", "delete"]
    priority: Literal[1, 2, 3, 4]
    payload: dict[str, Any]
    event_log: list[EventLogEntry] = []
    device_timestamp: int
    client_watermark: int = 0


class SyncPushRequest(BaseModel):
    device_id: str
    worker_id: str
    app_version: str
    batch_id: str = Field(..., description="UUID for idempotent retry detection")
    sent_at: int = Field(..., description="Unix ms, device clock")
    records: list[SyncRecord]


class ConflictItem(BaseModel):
    record_id: str
    table: str
    conflict_type: Literal["field_conflict", "duplicate_identity"]
    both_values: list[dict[str, Any]]
    resolution: Literal["auto_merged", "flagged_for_review"]


class SyncPushResponse(BaseModel):
    batch_id: str
    server_received_at: int
    synced: list[str]
    conflicts: list[ConflictItem]
    server_watermarks: dict[str, int]


class SyncPullResponse(BaseModel):
    records: list[dict[str, Any]]
    server_watermarks: dict[str, int]
    has_more: bool


# ── Referral schemas ──────────────────────────────────────────────────────────


class ReferralOutcomeRequest(BaseModel):
    outcome: Literal["admitted", "treated_discharged", "counter_referred", "deceased"]
    receiving_facility_id: str | None = None
    receiving_facility_name: str | None = None
    doctor_name: str | None = None
    doctor_notes: str | None = None
    treatment_summary: str | None = None
    counter_referral_instructions: str | None = None
    outcome_recorded_at: int | None = None
    recorded_by: str | None = None


class ReferralFeedbackRequest(BaseModel):
    asha_id: str
    message: str
    sent_at: int | None = None


class ReferralStatusUpdateRequest(BaseModel):
    status: Literal["created", "en_route", "arrived", "outcome_recorded"]
    updated_at: int | None = None
    notes: str | None = None


class ReferralOutcomeResponse(BaseModel):
    referral_id: str
    status: str
    outcome: str
    outcome_recorded_at: int
    message: str
    timeline_entry: dict[str, Any] | None = None

