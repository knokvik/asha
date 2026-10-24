"""Allow prefixed and non-UUID IDs in sync tracking tables."""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op


revision = "20261024_09"
down_revision = "20261024_08"
branch_labels = None
depends_on = None


def upgrade() -> None:
    for table in ("sync_queue", "audit_log", "conflict_review", "outbound_sharing_log"):
        op.alter_column(
            table,
            "record_id",
            existing_type=sa.String(length=36),
            type_=sa.String(length=100),
            existing_nullable=False,
        )


def downgrade() -> None:
    # IDs such as ref_<uuid> cannot safely be truncated back to 36 chars.
    pass
