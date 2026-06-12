"""Create users table with supervisor seed

Revision ID: 001
Revises:
Create Date: 2026-06-08
"""
import os
import uuid
from typing import Sequence, Union

import bcrypt
import sqlalchemy as sa
from alembic import op

revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column("username", sa.String(50), nullable=False),
        sa.Column("display_name", sa.String(100), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("role", sa.String(50), nullable=False),
        sa.Column("status", sa.String(50), nullable=False, server_default="active"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("created_by_id", sa.dialects.postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=True),
    )
    op.create_index("ix_users_username", "users", ["username"], unique=True)
    op.create_index("ix_users_status", "users", ["status"])

    supervisor_id = uuid.uuid4()
    supervisor_username = os.environ.get("SUPERVISOR_USERNAME", "admin")
    supervisor_password = os.environ.get("SUPERVISOR_PASSWORD", "Admin2026")
    password_hash = bcrypt.hashpw(supervisor_password.encode(), bcrypt.gensalt()).decode()

    op.execute(
        sa.text(
            "INSERT INTO users (id, username, display_name, password_hash, role, status) "
            "VALUES (:id, :username, :display_name, :password_hash, :role, :status)"
        ).bindparams(
            sa.bindparam("id", value=supervisor_id, type_=sa.dialects.postgresql.UUID(as_uuid=True)),
            username=supervisor_username,
            display_name="Supervisor",
            password_hash=password_hash,
            role="supervisor",
            status="active",
        )
    )


def downgrade() -> None:
    op.drop_index("ix_users_status", table_name="users")
    op.drop_index("ix_users_username", table_name="users")
    op.drop_table("users")
