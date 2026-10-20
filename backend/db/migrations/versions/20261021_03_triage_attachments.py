"""Persist triage packets and their compressed evidence attachments.

Revision ID: 20261021_03
Revises: 20261019_02
"""
from __future__ import annotations

from alembic import op

from models.db.models import TriageTicket

revision = "20261021_03"
down_revision = "20261019_02"
branch_labels = None
depends_on = None


def upgrade() -> None:
    TriageTicket.__table__.create(bind=op.get_bind(), checkfirst=True)


def downgrade() -> None:
    TriageTicket.__table__.drop(bind=op.get_bind(), checkfirst=True)
