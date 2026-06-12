"""Create OT management tables

Revision ID: 002
Revises: 001
Create Date: 2026-06-08
"""
import uuid
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID as PGUUID

revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "technical_locations",
        sa.Column("id", PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column("sector", sa.String(100), nullable=False),
        sa.Column("subsector", sa.String(100), nullable=False),
        sa.Column("system", sa.String(100), nullable=False),
        sa.Column("subsystem", sa.String(100), nullable=False),
    )
    op.create_unique_constraint(
        "uq_tech_loc_leaf", "technical_locations",
        ["sector", "subsector", "system", "subsystem"]
    )
    op.create_index("ix_tech_loc_hierarchy", "technical_locations", ["sector", "subsector", "system"])

    op.create_table(
        "work_orders",
        sa.Column("id", PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column("order_type", sa.String(10), nullable=False),
        sa.Column("technical_location_id", PGUUID(as_uuid=True), sa.ForeignKey("technical_locations.id"), nullable=False),
        sa.Column("assigned_technician_id", PGUUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("created_by_id", PGUUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("planner_group", sa.String(50), nullable=False),
        sa.Column("activity_class", sa.String(100), nullable=False),
        sa.Column("installation_state", sa.String(20), nullable=False),
        sa.Column("planned_start", sa.Date, nullable=False),
        sa.Column("planned_end", sa.Date, nullable=False),
        sa.Column("priority", sa.SmallInteger, nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="released"),
        sa.Column("notif_final", sa.Boolean, nullable=False, server_default="false"),
        sa.Column("sin_ttbjo_real", sa.Boolean, nullable=False, server_default="false"),
        sa.Column("shift_number", sa.SmallInteger, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.CheckConstraint("priority BETWEEN 1 AND 4", name="ck_wo_priority"),
        sa.CheckConstraint("shift_number BETWEEN 1 AND 3", name="ck_wo_shift"),
    )
    op.create_index("ix_wo_tech_shift_status", "work_orders", ["assigned_technician_id", "shift_number", "status"])
    op.create_index("ix_wo_shift_status", "work_orders", ["shift_number", "status"])

    op.create_table(
        "ot_steps",
        sa.Column("id", PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column("work_order_id", PGUUID(as_uuid=True), sa.ForeignKey("work_orders.id", ondelete="CASCADE"), nullable=False),
        sa.Column("position", sa.SmallInteger, nullable=False),
        sa.Column("description", sa.Text, nullable=False),
        sa.Column("control_key", sa.String(10), nullable=False),
        sa.Column("planned_intervention_time", sa.Numeric(5, 2), nullable=True),
        sa.Column("is_fixed", sa.Boolean, nullable=False, server_default="false"),
        sa.UniqueConstraint("work_order_id", "position", name="uq_step_position"),
    )

    op.create_table(
        "step_closures",
        sa.Column("id", PGUUID(as_uuid=True), primary_key=True, default=uuid.uuid4),
        sa.Column("step_id", PGUUID(as_uuid=True), sa.ForeignKey("ot_steps.id"), nullable=False, unique=True),
        sa.Column("actual_duration", sa.Numeric(5, 2), nullable=False),
        sa.Column("deviation_key", sa.String(30), nullable=False),
        sa.Column("work_description", sa.Text, nullable=False),
        sa.Column("safety_question_response", sa.Boolean, nullable=False),
        sa.Column("submitted_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.CheckConstraint("actual_duration > 0", name="ck_closure_duration"),
    )


def downgrade() -> None:
    op.drop_table("step_closures")
    op.drop_table("ot_steps")
    op.drop_index("ix_wo_shift_status", table_name="work_orders")
    op.drop_index("ix_wo_tech_shift_status", table_name="work_orders")
    op.drop_table("work_orders")
    op.drop_index("ix_tech_loc_hierarchy", table_name="technical_locations")
    op.drop_constraint("uq_tech_loc_leaf", "technical_locations")
    op.drop_table("technical_locations")
