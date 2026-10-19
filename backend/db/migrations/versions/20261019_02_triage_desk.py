"""Add the PHC desk tables used by the adaptive-triage sync loop.

Revision ID: 20261019_02
Revises: 20261016_01
"""
from __future__ import annotations

from alembic import op

from models.db.desk import (
    ContextPackBlob,
    DeskIdempotency,
    DeskOutcome,
    DeskTicket,
    DiseaseCountRow,
)

revision = "20261019_02"
down_revision = "20261016_01"
branch_labels = None
depends_on = None

_TABLES = (
    DeskTicket.__table__,
    DeskOutcome.__table__,
    DeskIdempotency.__table__,
    ContextPackBlob.__table__,
    DiseaseCountRow.__table__,
)


def upgrade() -> None:
    bind = op.get_bind()
    for table in _TABLES:
        table.create(bind=bind, checkfirst=True)


def downgrade() -> None:
    bind = op.get_bind()
    for table in reversed(_TABLES):
        table.drop(bind=bind, checkfirst=True)
