"""Prompt 2 tables. They sit beside the existing sync schema.

Merge rule for the next context pack: each ward/week/condition keeps the row
with the later observed_at. If both timestamps match, an app-reported syndromic
flag wins over the seeded IDSP baseline.
"""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Index, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from models.db.base import Base


def _uuid() -> str:
    return str(uuid.uuid4())


def _now() -> datetime:
    return datetime.utcnow()


class DeskTicket(Base):
    __tablename__ = "desk_tickets"
    __table_args__ = (
        UniqueConstraint("referral_id", name="uq_desk_tickets_referral"),
        Index("idx_desk_tickets_queue", "district_id", "status", "priority"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    referral_id: Mapped[str] = mapped_column(String(64), nullable=False)
    priority: Mapped[str] = mapped_column(String(10), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="NEW")
    district_id: Mapped[str] = mapped_column(String(32), nullable=False, default="PCMC")
    ward_id: Mapped[str] = mapped_column(String(16), nullable=False)
    asha_id: Mapped[str] = mapped_column(String(64), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    sla_due_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    escalated_level: Mapped[int] = mapped_column(Integer, default=0)
    acknowledged_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    payload_json: Mapped[str] = mapped_column(Text, nullable=False, default="{}")
    idempotency_key: Mapped[str | None] = mapped_column(String(80), nullable=True)


class DeskOutcome(Base):
    __tablename__ = "desk_outcomes"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    ticket_id: Mapped[str] = mapped_column(String(36), nullable=False, unique=True)
    diagnosis: Mapped[str] = mapped_column(Text, nullable=False)
    action: Mapped[str] = mapped_column(String(32), nullable=False)
    note_for_asha: Mapped[str] = mapped_column(Text, default="")
    outcome_label_for_ml: Mapped[str] = mapped_column(String(32), nullable=False)
    fhir_json: Mapped[str] = mapped_column(Text, nullable=False, default="{}")
    recorded_at: Mapped[datetime] = mapped_column(DateTime, default=_now)


class DeskIdempotency(Base):
    __tablename__ = "desk_idempotency"

    key: Mapped[str] = mapped_column(String(80), primary_key=True)
    item_type: Mapped[str] = mapped_column(String(32), nullable=False)
    ticket_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)


class ContextPackBlob(Base):
    __tablename__ = "context_packs"
    __table_args__ = (UniqueConstraint("district_id", "version", name="uq_context_pack_version"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    district_id: Mapped[str] = mapped_column(String(32), nullable=False)
    version: Mapped[int] = mapped_column(Integer, nullable=False)
    etag: Mapped[str] = mapped_column(String(64), nullable=False)
    body_json: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)


class DiseaseCountRow(Base):
    __tablename__ = "disease_counts"
    __table_args__ = (
        UniqueConstraint(
            "district_id",
            "ward_id",
            "week_index",
            "condition",
            "source",
            name="uq_disease_count_source",
        ),
        Index("idx_disease_counts_heat", "district_id", "week_index", "ward_id"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    district_id: Mapped[str] = mapped_column(String(32), nullable=False)
    ward_id: Mapped[str] = mapped_column(String(16), nullable=False)
    week_index: Mapped[int] = mapped_column(Integer, nullable=False)
    condition: Mapped[str] = mapped_column(String(32), nullable=False)
    count: Mapped[int] = mapped_column(Integer, nullable=False)
    source: Mapped[str] = mapped_column(String(16), nullable=False)
    observed_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
