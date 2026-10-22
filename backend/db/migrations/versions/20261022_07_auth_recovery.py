"""Add contact identifiers and server-side password recovery fields."""
from alembic import op
import sqlalchemy as sa

revision = "20261022_07"
down_revision = "20261021_06"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("users", sa.Column("email", sa.String(length=320), nullable=True))
    op.create_index("ix_users_email", "users", ["email"], unique=True)
    op.add_column("users", sa.Column("phone", sa.String(length=20), nullable=True))
    op.create_index("ix_users_phone", "users", ["phone"], unique=True)
    op.add_column("users", sa.Column("password_reset_token_hash", sa.String(length=128), nullable=True))
    op.add_column("users", sa.Column("password_reset_expires_at", sa.BigInteger(), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "password_reset_expires_at")
    op.drop_column("users", "password_reset_token_hash")
    op.drop_index("ix_users_phone", table_name="users")
    op.drop_column("users", "phone")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_column("users", "email")
