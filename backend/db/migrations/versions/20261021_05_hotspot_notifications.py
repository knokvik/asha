"""Add hotspot coordinates and durable area recommendations.

Revision ID: 20261021_05
Revises: 20261021_04
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "20261021_05"
down_revision = "20261021_04"
branch_labels = None
depends_on = None


def _add_if_missing(table: str, column: sa.Column[object]) -> None:
    columns = {item["name"] for item in sa.inspect(op.get_bind()).get_columns(table)}
    if column.name not in columns:
        op.add_column(table, column)


def upgrade() -> None:
    _add_if_missing("triage_tickets", sa.Column("latitude", sa.Float(), nullable=True))
    _add_if_missing("triage_tickets", sa.Column("longitude", sa.Float(), nullable=True))
    op.create_table(
        "area_notifications",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("block_code", sa.String(length=32), nullable=False),
        sa.Column("ward_id", sa.String(length=32), nullable=False),
        sa.Column("module_id", sa.String(length=64), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("severity", sa.String(length=16), nullable=False, server_default="standard"),
        sa.Column("created_at", sa.BigInteger(), nullable=False),
        sa.Column("expires_at", sa.BigInteger(), nullable=False),
        sa.Column("dedupe_key", sa.String(length=128), nullable=False, unique=True),
    )
    op.create_index(
        "idx_area_notifications_recipient",
        "area_notifications",
        ["block_code", "created_at"],
    )


def downgrade() -> None:
    op.drop_index("idx_area_notifications_recipient", table_name="area_notifications")
    op.drop_table("area_notifications")
    op.drop_column("triage_tickets", "longitude")
    op.drop_column("triage_tickets", "latitude")
