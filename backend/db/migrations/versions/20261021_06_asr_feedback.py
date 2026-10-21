"""Store privacy-preserving ASR correction feedback.

Revision ID: 20261021_06
Revises: 20261021_05
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "20261021_06"
down_revision = "20261021_05"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "asr_feedback",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("worker_id", sa.String(length=36), nullable=False),
        sa.Column("block_code", sa.String(length=32), nullable=True),
        sa.Column("raw_transcript", sa.Text(), nullable=True),
        sa.Column("raw_hash", sa.String(length=64), nullable=False),
        sa.Column("canonical_value", sa.Text(), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("accepted", sa.Boolean(), nullable=False),
        sa.Column("language", sa.String(length=16), nullable=False),
        sa.Column("field_type", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.BigInteger(), nullable=False),
        sa.Column("raw_retention_opt_in", sa.Boolean(), nullable=False),
    )
    op.create_index("idx_asr_feedback_language", "asr_feedback", ["language", "created_at"])


def downgrade() -> None:
    op.drop_index("idx_asr_feedback_language", table_name="asr_feedback")
    op.drop_table("asr_feedback")
