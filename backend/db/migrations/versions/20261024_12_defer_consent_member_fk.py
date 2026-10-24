"""Allow consent packets to arrive before their member packet."""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op


revision = "20261024_12"
down_revision = "20261024_11"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Keep the member_id value, but do not reject an offline consent packet
    # merely because the member packet has not arrived yet.
    op.drop_constraint(
        "consent_records_member_id_fkey",
        "consent_records",
        type_="foreignkey",
    )
    op.alter_column(
        "consent_records",
        "member_id",
        existing_type=sa.String(length=36),
        type_=sa.String(length=100),
        nullable=True,
        existing_nullable=False,
    )


def downgrade() -> None:
    # Re-adding the constraint may fail if orphaned consent packets exist;
    # restoration must be handled after reconciliation.
    pass
