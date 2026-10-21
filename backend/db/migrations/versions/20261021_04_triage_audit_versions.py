"""Persist engine and model versions with every triage result and ticket.

Revision ID: 20261021_04
Revises: 20261021_03
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "20261021_04"
down_revision = "20261021_03"
branch_labels = None
depends_on = None


def _add_if_missing(table: str, column: sa.Column[object]) -> None:
    columns = {item["name"] for item in sa.inspect(op.get_bind()).get_columns(table)}
    if column.name not in columns:
        op.add_column(table, column)


def upgrade() -> None:
    _add_if_missing(
        "triage_results",
        sa.Column("engine_version", sa.String(length=64), nullable=True),
    )
    _add_if_missing(
        "triage_results",
        sa.Column("model_version", sa.String(length=64), nullable=True),
    )
    _add_if_missing(
        "triage_tickets",
        sa.Column("engine_version", sa.String(length=64), nullable=True),
    )
    _add_if_missing(
        "triage_tickets",
        sa.Column("model_version", sa.String(length=64), nullable=True),
    )


def downgrade() -> None:
    for table, column in (
        ("triage_tickets", "model_version"),
        ("triage_tickets", "engine_version"),
        ("triage_results", "model_version"),
        ("triage_results", "engine_version"),
    ):
        columns = {item["name"] for item in sa.inspect(op.get_bind()).get_columns(table)}
        if column in columns:
            op.drop_column(table, column)
