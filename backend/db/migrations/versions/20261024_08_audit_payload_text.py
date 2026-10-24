"""Allow audit log payloads larger than a UUID.

The sync service stores JSON snapshots in ``old_value`` and ``new_value``.
The initial schema declared these columns as VARCHAR(36), which caused a
PostgreSQL StringDataRightTruncationError when syncing referral or household
packets and left the request in PendingRollbackError during session cleanup.
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op


revision = "20261024_08"
down_revision = "20261022_07"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column(
        "audit_log",
        "old_value",
        existing_type=sa.String(length=36),
        type_=sa.Text(),
        existing_nullable=True,
    )
    op.alter_column(
        "audit_log",
        "new_value",
        existing_type=sa.String(length=36),
        type_=sa.Text(),
        existing_nullable=True,
    )


def downgrade() -> None:
    # Existing JSON audit payloads may exceed 36 characters; truncating them
    # would be destructive, so retain Text rather than silently losing data.
    pass
