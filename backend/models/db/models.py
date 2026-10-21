"""SQLAlchemy ORM models mirroring the mobile schema plus server-side columns.

Every synced table includes these extra server columns:
    worker_id          — owning ASHA worker (FK to users.id)
    server_received_at — timestamp when backend first received the record
    server_seq         — monotonically increasing server sequence for delta pull
    state_code         — geographic isolation (from JWT at ingest time)
    district_code
    block_code
"""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.db.base import Base

# ── Helper ────────────────────────────────────────────────────────────────────


def _uuid() -> str:
    return str(uuid.uuid4())


def _now() -> datetime:
    return datetime.utcnow()


# ── Core entity tables ────────────────────────────────────────────────────────


class User(Base):
    """ASHA worker / supervisor / admin account."""

    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    asha_id: Mapped[str | None] = mapped_column(String(50), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[str] = mapped_column(String(50), nullable=False)
    area_village: Mapped[str | None] = mapped_column(Text)
    area_subcentre: Mapped[str | None] = mapped_column(Text)
    area_phc: Mapped[str | None] = mapped_column(Text)
    area_block: Mapped[str | None] = mapped_column(String(100))
    area_district: Mapped[str | None] = mapped_column(String(100))
    area_state: Mapped[str | None] = mapped_column(String(100))
    hashed_pin: Mapped[str | None] = mapped_column(String(255))
    pin_salt: Mapped[str | None] = mapped_column(Text)
    offline_credential_hash: Mapped[str | None] = mapped_column(String(255))
    offline_cred_expires_at: Mapped[int | None] = mapped_column(BigInteger)
    jwt_refresh_token: Mapped[str | None] = mapped_column(Text)
    last_jwt_refresh_at: Mapped[int | None] = mapped_column(BigInteger)
    failed_pin_attempts: Mapped[int] = mapped_column(Integer, default=0)
    lockout_until: Mapped[int | None] = mapped_column(BigInteger)
    state_code: Mapped[str | None] = mapped_column(String(10))
    district_code: Mapped[str | None] = mapped_column(String(10))
    block_code: Mapped[str | None] = mapped_column(String(10))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=_now, onupdate=_now)
    sync_status: Mapped[str] = mapped_column(String(20), default="synced")


class Household(Base):
    __tablename__ = "households"
    __table_args__ = (Index("idx_households_block", "block_code"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    village: Mapped[str | None] = mapped_column(String(255))
    hamlet: Mapped[str | None] = mapped_column(String(255))
    head_name: Mapped[str | None] = mapped_column(String(255))
    social_category: Mapped[str | None] = mapped_column(String(50))
    is_bpl: Mapped[bool | None] = mapped_column(Boolean)
    contact_phone: Mapped[str | None] = mapped_column(String(20))
    latitude: Mapped[str | None] = mapped_column(String(20))
    longitude: Mapped[str | None] = mapped_column(String(20))
    landmark_notes: Mapped[str | None] = mapped_column(Text)
    member_count: Mapped[int | None] = mapped_column(Integer)
    created_at: Mapped[int | None] = mapped_column(BigInteger)
    updated_at: Mapped[int | None] = mapped_column(BigInteger)
    created_by: Mapped[str | None] = mapped_column(String(36))
    sync_status: Mapped[str] = mapped_column(String(20), default="pending")
    server_version: Mapped[int | None] = mapped_column(Integer)
    # Server-side extras
    worker_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"))
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    server_seq: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    state_code: Mapped[str | None] = mapped_column(String(10))
    district_code: Mapped[str | None] = mapped_column(String(10))
    block_code: Mapped[str | None] = mapped_column(String(10))

    members: Mapped[list[Member]] = relationship("Member", back_populates="household")


class Member(Base):
    __tablename__ = "members"
    __table_args__ = (
        Index("idx_members_household", "household_id"),
        Index("idx_members_block", "block_code"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    household_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("households.id"))
    name: Mapped[str | None] = mapped_column(String(255))
    name_phonetic: Mapped[str | None] = mapped_column(String(255))
    dob_approx: Mapped[int | None] = mapped_column(BigInteger)
    is_dob_approx: Mapped[bool | None] = mapped_column(Boolean)
    sex: Mapped[str | None] = mapped_column(String(10))
    relationship_to_head: Mapped[str | None] = mapped_column(String(50))
    abha_id: Mapped[str | None] = mapped_column(String(50))
    rch_id: Mapped[str | None] = mapped_column(String(50))
    phone: Mapped[str | None] = mapped_column(String(20))
    social_category: Mapped[str | None] = mapped_column(String(50))
    is_bpl: Mapped[bool | None] = mapped_column(Boolean)
    lifecycle_status: Mapped[str | None] = mapped_column(String(50))
    consent_status: Mapped[str | None] = mapped_column(String(20))
    consent_updated_at: Mapped[int | None] = mapped_column(BigInteger)
    created_at: Mapped[int | None] = mapped_column(BigInteger)
    updated_at: Mapped[int | None] = mapped_column(BigInteger)
    created_by: Mapped[str | None] = mapped_column(String(36))
    sync_status: Mapped[str] = mapped_column(String(20), default="pending")
    server_version: Mapped[int | None] = mapped_column(Integer)
    # Server-side extras
    worker_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"))
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    server_seq: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    state_code: Mapped[str | None] = mapped_column(String(10))
    district_code: Mapped[str | None] = mapped_column(String(10))
    block_code: Mapped[str | None] = mapped_column(String(10))

    household: Mapped[Household | None] = relationship("Household", back_populates="members")
    encounters: Mapped[list[ClinicalEncounter]] = relationship("ClinicalEncounter", back_populates="member")
    consent_records: Mapped[list[ConsentRecord]] = relationship("ConsentRecord", back_populates="member")


class ConsentRecord(Base):
    __tablename__ = "consent_records"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    member_id: Mapped[str] = mapped_column(String(36), ForeignKey("members.id"), nullable=False)
    consent_version: Mapped[str | None] = mapped_column(String(20))
    consented_at: Mapped[int | None] = mapped_column(BigInteger)
    asha_id: Mapped[str | None] = mapped_column(String(50))
    witness_type: Mapped[str | None] = mapped_column(String(50))
    signature_hash: Mapped[str | None] = mapped_column(String(255))
    withdrawn_at: Mapped[int | None] = mapped_column(BigInteger)
    withdrawal_reason: Mapped[str | None] = mapped_column(Text)
    sync_status: Mapped[str] = mapped_column(String(20), default="pending")
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    server_seq: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    block_code: Mapped[str | None] = mapped_column(String(10))

    member: Mapped[Member] = relationship("Member", back_populates="consent_records")


class ClinicalEncounter(Base):
    __tablename__ = "clinical_encounters"
    __table_args__ = (
        Index("idx_encounters_member_program", "member_id", "program_code"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    member_id: Mapped[str] = mapped_column(String(36), ForeignKey("members.id"), nullable=False)
    encounter_type: Mapped[str | None] = mapped_column(String(50))
    program_code: Mapped[str | None] = mapped_column(String(50))
    encounter_date: Mapped[int | None] = mapped_column(BigInteger)
    asha_id: Mapped[str | None] = mapped_column(String(50))
    rule_version_id: Mapped[str | None] = mapped_column(String(36))
    status: Mapped[str | None] = mapped_column(String(20))
    visit_notes: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[int | None] = mapped_column(BigInteger)
    updated_at: Mapped[int | None] = mapped_column(BigInteger)
    sync_status: Mapped[str] = mapped_column(String(20), default="pending")
    server_version: Mapped[int | None] = mapped_column(Integer)
    # Server-side extras
    worker_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"))
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    server_seq: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    block_code: Mapped[str | None] = mapped_column(String(10))

    member: Mapped[Member] = relationship("Member", back_populates="encounters")
    observations: Mapped[list[ClinicalObservation]] = relationship("ClinicalObservation", back_populates="encounter")
    triage_result: Mapped[TriageResult | None] = relationship("TriageResult", back_populates="encounter", uselist=False)
    referral: Mapped[ReferralRecord | None] = relationship("ReferralRecord", back_populates="encounter", uselist=False)


class ClinicalObservation(Base):
    __tablename__ = "clinical_observations"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    encounter_id: Mapped[str] = mapped_column(String(36), ForeignKey("clinical_encounters.id"), nullable=False)
    observation_code: Mapped[str | None] = mapped_column(String(50))
    value_text: Mapped[str | None] = mapped_column(Text)
    value_numeric: Mapped[float | None] = mapped_column(Float)
    value_unit: Mapped[str | None] = mapped_column(String(20))
    value_enum: Mapped[str | None] = mapped_column(String(100))
    source: Mapped[str | None] = mapped_column(String(50))
    observed_at: Mapped[int | None] = mapped_column(BigInteger)
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    encounter: Mapped[ClinicalEncounter] = relationship("ClinicalEncounter", back_populates="observations")


class TriageResult(Base):
    __tablename__ = "triage_results"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    encounter_id: Mapped[str] = mapped_column(String(36), ForeignKey("clinical_encounters.id"), nullable=False, unique=True)
    flag: Mapped[str | None] = mapped_column(String(10))
    rule_version_id: Mapped[str | None] = mapped_column(String(36))
    engine_version: Mapped[str | None] = mapped_column(String(64))
    model_version: Mapped[str | None] = mapped_column(String(64))
    findings_json: Mapped[str | None] = mapped_column(Text)
    override_flag: Mapped[str | None] = mapped_column(String(10))
    override_reason: Mapped[str | None] = mapped_column(Text)
    override_voice_note_path: Mapped[str | None] = mapped_column(Text)
    overriding_user_id: Mapped[str | None] = mapped_column(String(36))
    evaluated_at: Mapped[int | None] = mapped_column(BigInteger)
    overridden_at: Mapped[int | None] = mapped_column(BigInteger)
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    encounter: Mapped[ClinicalEncounter] = relationship("ClinicalEncounter", back_populates="triage_result")


class TriageTicket(Base):
    """Offline triage packet, including optional compressed evidence."""

    __tablename__ = "triage_tickets"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str | None] = mapped_column(String(255))
    age_months: Mapped[int | None] = mapped_column(Integer)
    location: Mapped[str | None] = mapped_column(String(255))
    additional_details: Mapped[str | None] = mapped_column(Text)
    ward_id: Mapped[str | None] = mapped_column(String(32))
    flag: Mapped[str | None] = mapped_column(String(16))
    sms: Mapped[str | None] = mapped_column(Text)
    modules_json: Mapped[str] = mapped_column(Text, default="[]")
    worker_modules_json: Mapped[str] = mapped_column(Text, default="[]")
    attachments_json: Mapped[str] = mapped_column(Text, default="[]")
    engine_version: Mapped[str | None] = mapped_column(String(64))
    model_version: Mapped[str | None] = mapped_column(String(64))
    created_at: Mapped[int | None] = mapped_column(BigInteger)
    updated_at: Mapped[int | None] = mapped_column(BigInteger)
    sync_status: Mapped[str] = mapped_column(String(20), default="synced")
    worker_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"))
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    block_code: Mapped[str | None] = mapped_column(String(10))
    server_seq: Mapped[int | None] = mapped_column(BigInteger, nullable=True)


class ReferralRecord(Base):
    __tablename__ = "referral_records"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    encounter_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("clinical_encounters.id"), unique=True)
    member_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("members.id"))
    triage_flag: Mapped[str | None] = mapped_column(String(10))
    destination_facility_id: Mapped[str | None] = mapped_column(String(36))
    destination_level: Mapped[str | None] = mapped_column(String(50))
    transport_arranged: Mapped[str | None] = mapped_column(String(50))
    status: Mapped[str | None] = mapped_column(String(20))
    outcome: Mapped[str | None] = mapped_column(String(50))
    outcome_recorded_by: Mapped[str | None] = mapped_column(String(36))
    outcome_recorded_at: Mapped[int | None] = mapped_column(BigInteger)
    referral_note_text: Mapped[str | None] = mapped_column(Text)
    referral_pdf_path: Mapped[str | None] = mapped_column(Text)
    referral_qr_data: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[int | None] = mapped_column(BigInteger)
    updated_at: Mapped[int | None] = mapped_column(BigInteger)
    sync_status: Mapped[str] = mapped_column(String(20), default="pending")
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    block_code: Mapped[str | None] = mapped_column(String(10))
    server_seq: Mapped[int | None] = mapped_column(BigInteger, nullable=True)

    encounter: Mapped[ClinicalEncounter | None] = relationship("ClinicalEncounter", back_populates="referral")


class VisitSchedule(Base):
    __tablename__ = "visit_schedules"
    __table_args__ = (Index("idx_visit_schedules_due", "due_date", "status"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    member_id: Mapped[str] = mapped_column(String(36), ForeignKey("members.id"), nullable=False)
    program_code: Mapped[str | None] = mapped_column(String(50))
    visit_type: Mapped[str | None] = mapped_column(String(50))
    due_date: Mapped[int | None] = mapped_column(BigInteger)
    due_window_start: Mapped[int | None] = mapped_column(BigInteger)
    due_window_end: Mapped[int | None] = mapped_column(BigInteger)
    status: Mapped[str | None] = mapped_column(String(20))
    skip_reason: Mapped[str | None] = mapped_column(Text)
    completed_at: Mapped[int | None] = mapped_column(BigInteger)
    completed_encounter_id: Mapped[str | None] = mapped_column(String(36))
    created_at: Mapped[int | None] = mapped_column(BigInteger)
    rescheduled_count: Mapped[int] = mapped_column(Integer, default=0)
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    block_code: Mapped[str | None] = mapped_column(String(10))
    server_seq: Mapped[int | None] = mapped_column(BigInteger, nullable=True)


class IncentiveEvent(Base):
    __tablename__ = "incentive_events"
    __table_args__ = (
        UniqueConstraint("idempotency_key", name="uq_incentive_events_idempotency"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    worker_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"), nullable=True)
    member_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("members.id"))
    encounter_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("clinical_encounters.id"))
    activity_code: Mapped[str | None] = mapped_column(String(50))
    catalogue_version_id: Mapped[str | None] = mapped_column(String(36))
    event_date: Mapped[int | None] = mapped_column(BigInteger)
    status: Mapped[str | None] = mapped_column(String(20))
    ineligibility_reason: Mapped[str | None] = mapped_column(Text)
    evidence_record_id: Mapped[str | None] = mapped_column(String(36))
    created_at: Mapped[int | None] = mapped_column(BigInteger)
    idempotency_key: Mapped[str] = mapped_column(String(100), nullable=False)
    sync_status: Mapped[str] = mapped_column(String(20), default="pending")
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    block_code: Mapped[str | None] = mapped_column(String(10))
    flagged_reason: Mapped[str | None] = mapped_column(Text, nullable=True)


class IncentiveCatalogue(Base):
    __tablename__ = "incentive_catalogues"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    version_id: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    state_code: Mapped[str] = mapped_column(String(10), default="DEFAULT", nullable=False)
    effective_from: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    effective_to: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    description: Mapped[str | None] = mapped_column(Text)
    catalogue_json: Mapped[str] = mapped_column(Text, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)


class IncentiveClaim(Base):
    __tablename__ = "incentive_claims"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    worker_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"))
    claim_period: Mapped[str | None] = mapped_column(String(20))
    status: Mapped[str | None] = mapped_column(String(20))
    line_items_json: Mapped[str | None] = mapped_column(Text)
    total_amount: Mapped[float | None] = mapped_column(Float)
    pdf_path: Mapped[str | None] = mapped_column(Text)
    payment_reference: Mapped[str | None] = mapped_column(String(100))
    submitted_at: Mapped[int | None] = mapped_column(BigInteger)
    verified_at: Mapped[int | None] = mapped_column(BigInteger)
    paid_at: Mapped[int | None] = mapped_column(BigInteger)
    sync_status: Mapped[str] = mapped_column(String(20), default="pending")
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)


class SyncQueue(Base):
    __tablename__ = "sync_queue"
    __table_args__ = (Index("idx_sync_queue_pending", "priority", "created_at"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    table_name: Mapped[str] = mapped_column(String(50), nullable=False)
    record_id: Mapped[str] = mapped_column(String(36), nullable=False)
    priority: Mapped[int] = mapped_column(Integer, nullable=False)
    operation: Mapped[str] = mapped_column(String(10), nullable=False)
    payload_json: Mapped[str | None] = mapped_column(Text)
    sync_status: Mapped[str] = mapped_column(String(20), default="pending")
    created_at: Mapped[int | None] = mapped_column(BigInteger)
    last_attempt_at: Mapped[int | None] = mapped_column(BigInteger)
    attempt_count: Mapped[int] = mapped_column(Integer, default=0)
    error_message: Mapped[str | None] = mapped_column(Text)


class RuleVersion(Base):
    __tablename__ = "rule_versions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    version_string: Mapped[str] = mapped_column(String(50), nullable=False)
    published_at: Mapped[int | None] = mapped_column(BigInteger)
    bundle_hash: Mapped[str | None] = mapped_column(String(64))
    bundle_path: Mapped[str | None] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, default=False)
    clinical_lead_id: Mapped[str | None] = mapped_column(String(36))
    approval_signature: Mapped[str | None] = mapped_column(Text)


class AuditLog(Base):
    __tablename__ = "audit_log"
    __table_args__ = (
        Index("idx_audit_log_record", "table_name", "record_id", "device_timestamp"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    table_name: Mapped[str] = mapped_column(String(50), nullable=False)
    record_id: Mapped[str] = mapped_column(String(36), nullable=False)
    field_name: Mapped[str | None] = mapped_column(String(100))
    old_value: Mapped[str | None] = mapped_column(Text)
    new_value: Mapped[str | None] = mapped_column(Text)
    changed_by: Mapped[str | None] = mapped_column(String(36))
    device_id: Mapped[str | None] = mapped_column(String(100))
    app_version: Mapped[str | None] = mapped_column(String(30))
    rule_version_id: Mapped[str | None] = mapped_column(String(36))
    device_timestamp: Mapped[int | None] = mapped_column(BigInteger)
    server_timestamp: Mapped[int | None] = mapped_column(BigInteger)
    chain_hash: Mapped[str | None] = mapped_column(String(64))


class FacilityDirectory(Base):
    __tablename__ = "facility_directory"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    name: Mapped[str | None] = mapped_column(String(255))
    facility_level: Mapped[str | None] = mapped_column(String(50))
    district: Mapped[str | None] = mapped_column(String(100))
    block: Mapped[str | None] = mapped_column(String(100))
    village: Mapped[str | None] = mapped_column(String(100))
    latitude: Mapped[float | None] = mapped_column(Float)
    longitude: Mapped[float | None] = mapped_column(Float)
    contact_phone: Mapped[str | None] = mapped_column(String(20))
    services_json: Mapped[str | None] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_updated_at: Mapped[int | None] = mapped_column(BigInteger)


class StockItem(Base):
    __tablename__ = "stock_items"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    worker_id: Mapped[str | None] = mapped_column(String(36))
    item_code: Mapped[str | None] = mapped_column(String(50))
    item_name: Mapped[str | None] = mapped_column(String(255))
    quantity: Mapped[float | None] = mapped_column(Float)
    min_threshold: Mapped[float | None] = mapped_column(Float)
    unit: Mapped[str | None] = mapped_column(String(20))
    last_updated_at: Mapped[int | None] = mapped_column(BigInteger)
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)


class StockTransaction(Base):
    __tablename__ = "stock_transactions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    item_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("stock_items.id"))
    transaction_type: Mapped[str | None] = mapped_column(String(20))
    quantity_delta: Mapped[float | None] = mapped_column(Float)
    related_encounter_id: Mapped[str | None] = mapped_column(String(36))
    related_member_id: Mapped[str | None] = mapped_column(String(36))
    recorded_at: Mapped[int | None] = mapped_column(BigInteger)
    sync_status: Mapped[str] = mapped_column(String(20), default="pending")
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)


class StockOutEvent(Base):
    __tablename__ = "stock_out_events"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    worker_id: Mapped[str | None] = mapped_column(String(36))
    item_id: Mapped[str | None] = mapped_column(String(36))
    item_code: Mapped[str | None] = mapped_column(String(50))
    item_name: Mapped[str | None] = mapped_column(String(255))
    stock_out_date: Mapped[str] = mapped_column(String(50))
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)


class LearningProgress(Base):
    __tablename__ = "learning_progress"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    worker_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"))
    module_id: Mapped[str | None] = mapped_column(String(50))
    lesson_id: Mapped[str | None] = mapped_column(String(50))
    status: Mapped[str | None] = mapped_column(String(20))
    score: Mapped[int | None] = mapped_column(Integer)
    started_at: Mapped[int | None] = mapped_column(BigInteger)
    completed_at: Mapped[int | None] = mapped_column(BigInteger)
    quiz_attempts: Mapped[int] = mapped_column(Integer, default=0)
    server_received_at: Mapped[datetime] = mapped_column(DateTime, default=_now)


class DeviceProfile(Base):
    __tablename__ = "device_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    device_name: Mapped[str | None] = mapped_column(String(255))
    ble_service_uuid: Mapped[str | None] = mapped_column(String(50))
    ble_characteristic_uuid: Mapped[str | None] = mapped_column(String(50))
    measurement_type: Mapped[str | None] = mapped_column(String(50))
    unit: Mapped[str | None] = mapped_column(String(20))
    min_plausible: Mapped[float | None] = mapped_column(Float)
    max_plausible: Mapped[float | None] = mapped_column(Float)
    unit_conversion_json: Mapped[str | None] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


# ── Server-only conflict / merge tables ───────────────────────────────────────


class ConflictReview(Base):
    __tablename__ = "conflict_review"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    table_name: Mapped[str] = mapped_column(String(50), nullable=False)
    record_id: Mapped[str] = mapped_column(String(36), nullable=False)
    conflict_type: Mapped[str] = mapped_column(String(50), nullable=False)
    both_values: Mapped[str] = mapped_column(Text, nullable=False)  # JSON
    assigned_to: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"))
    status: Mapped[str] = mapped_column(String(20), default="pending")
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime)
    resolution_note: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)


class PendingMerge(Base):
    __tablename__ = "pending_merge"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    candidate_a_id: Mapped[str] = mapped_column(String(36), nullable=False)
    candidate_b_id: Mapped[str] = mapped_column(String(36), nullable=False)
    match_score: Mapped[float] = mapped_column(Float, nullable=False)
    match_fields: Mapped[str | None] = mapped_column(Text)  # JSON
    assigned_to: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"))
    status: Mapped[str] = mapped_column(String(20), default="pending")
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime)


class PaymentDispute(Base):
    __tablename__ = "payment_disputes"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    worker_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False)
    claim_period: Mapped[str] = mapped_column(String(20), nullable=False)
    claim_id: Mapped[str | None] = mapped_column(String(36))
    activity_code: Mapped[str | None] = mapped_column(String(50))
    dispute_type: Mapped[str] = mapped_column(String(50), default="technical_error")
    description: Mapped[str] = mapped_column(Text, nullable=False)
    evidence_event_ids_json: Mapped[str] = mapped_column(Text, default="[]")
    status: Mapped[str] = mapped_column(String(30), default="submitted")
    assigned_to: Mapped[str | None] = mapped_column(String(36))
    assigned_role: Mapped[str | None] = mapped_column(String(50))
    sla_deadline: Mapped[int | None] = mapped_column(BigInteger)
    is_escalated: Mapped[bool] = mapped_column(Boolean, default=False)
    escalation_level: Mapped[int] = mapped_column(Integer, default=0)
    resolution_notes: Mapped[str | None] = mapped_column(Text)
    resolved_by: Mapped[str | None] = mapped_column(String(36))
    resolved_at: Mapped[int | None] = mapped_column(BigInteger)
    created_at: Mapped[int] = mapped_column(BigInteger)
    updated_at: Mapped[int] = mapped_column(BigInteger)


class OutboundSharingLog(Base):
    """DPDP accountability log for external data sharing (Req 35.7)."""
    __tablename__ = "outbound_sharing_log"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    target_system: Mapped[str] = mapped_column(String(50), nullable=False)
    record_type: Mapped[str] = mapped_column(String(50), nullable=False)
    record_id: Mapped[str] = mapped_column(String(36), nullable=False)
    recipient: Mapped[str | None] = mapped_column(String(100))
    consent_artifact_id: Mapped[str | None] = mapped_column(String(36))
    payload_hash: Mapped[str | None] = mapped_column(String(64))
    shared_by: Mapped[str | None] = mapped_column(String(36))
    status: Mapped[str] = mapped_column(String(20), default="success")
    created_at: Mapped[int] = mapped_column(BigInteger)


class IntegrationIncident(Base):
    """Integration errors, format mismatches, and rejections (Req 35.5)."""
    __tablename__ = "integration_incidents"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    system_name: Mapped[str] = mapped_column(String(50), nullable=False)
    record_type: Mapped[str] = mapped_column(String(50), nullable=False)
    external_id: Mapped[str | None] = mapped_column(String(100))
    error_code: Mapped[str | None] = mapped_column(String(50))
    error_message: Mapped[str] = mapped_column(Text, nullable=False)
    raw_payload: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), default="open")
    resolved_at: Mapped[int | None] = mapped_column(BigInteger)
    resolution_notes: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[int] = mapped_column(BigInteger)


# Register the Prompt 2 desk tables on the same metadata.
from models.db import desk as _desk_models  # noqa: E402,F401


