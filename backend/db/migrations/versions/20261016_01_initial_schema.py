"""Create the initial ASHA server schema.

Revision ID: 20261016_01
Revises:
Create Date: 2026-10-16
"""
from __future__ import annotations

from alembic import op

from models.db.base import Base
import models.db.models  # noqa: F401 - register mapped tables

revision = "20261016_01"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    Base.metadata.create_all(bind=bind)


def downgrade() -> None:
    bind = op.get_bind()
    Base.metadata.drop_all(bind=bind)
