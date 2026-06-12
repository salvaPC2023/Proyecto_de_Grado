from datetime import date, datetime
from typing import Optional
from uuid import UUID, uuid4

from sqlalchemy import (
    Boolean, CheckConstraint, Date, DateTime, Enum as SAEnum,
    ForeignKey, Index, Integer, Numeric, SmallInteger, String, Text, UniqueConstraint, func,
)
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


# ── Feature 001: User Management ────────────────────────────────────────────

class UserORM(Base):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    username: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    display_name: Mapped[str] = mapped_column(String(100), nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[str] = mapped_column(String(50), nullable=False, default="active")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())
    created_by_id: Mapped[Optional[UUID]] = mapped_column(PGUUID(as_uuid=True), ForeignKey("users.id"), nullable=True)

    __table_args__ = (Index("ix_users_status", "status"),)


# ── Feature 002: OT Management ──────────────────────────────────────────────

class TechnicalLocationORM(Base):
    __tablename__ = "technical_locations"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    sector: Mapped[str] = mapped_column(String(100), nullable=False)
    subsector: Mapped[str] = mapped_column(String(100), nullable=False)
    system: Mapped[str] = mapped_column(String(100), nullable=False)
    subsystem: Mapped[str] = mapped_column(String(100), nullable=False)

    work_orders: Mapped[list["WorkOrderORM"]] = relationship(back_populates="technical_location_rel")

    __table_args__ = (
        UniqueConstraint("sector", "subsector", "system", "subsystem"),
        Index("ix_tech_loc_hierarchy", "sector", "subsector", "system"),
    )


class WorkOrderORM(Base):
    __tablename__ = "work_orders"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    order_type: Mapped[str] = mapped_column(String(10), nullable=False)
    technical_location_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("technical_locations.id"), nullable=False)
    assigned_technician_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_by_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    planner_group: Mapped[str] = mapped_column(String(50), nullable=False)
    activity_class: Mapped[str] = mapped_column(String(100), nullable=False)
    installation_state: Mapped[str] = mapped_column(String(20), nullable=False)
    planned_start: Mapped[date] = mapped_column(Date, nullable=False)
    planned_end: Mapped[date] = mapped_column(Date, nullable=False)
    priority: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="released")
    notif_final: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    sin_ttbjo_real: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    shift_number: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())

    technical_location_rel: Mapped["TechnicalLocationORM"] = relationship(back_populates="work_orders")
    steps: Mapped[list["OTStepORM"]] = relationship(back_populates="work_order", order_by="OTStepORM.position", cascade="all, delete-orphan")

    __table_args__ = (
        CheckConstraint("priority BETWEEN 1 AND 4", name="ck_wo_priority"),
        CheckConstraint("shift_number BETWEEN 1 AND 3", name="ck_wo_shift"),
        Index("ix_wo_tech_shift_status", "assigned_technician_id", "shift_number", "status"),
        Index("ix_wo_shift_status", "shift_number", "status"),
    )


class OTStepORM(Base):
    __tablename__ = "ot_steps"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    work_order_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("work_orders.id", ondelete="CASCADE"), nullable=False)
    position: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    control_key: Mapped[str] = mapped_column(String(10), nullable=False)
    planned_intervention_time: Mapped[Optional[float]] = mapped_column(Numeric(5, 2), nullable=True)
    is_fixed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    work_order: Mapped["WorkOrderORM"] = relationship(back_populates="steps")
    closure: Mapped[Optional["StepClosureORM"]] = relationship(back_populates="step", uselist=False, cascade="all, delete-orphan")

    __table_args__ = (UniqueConstraint("work_order_id", "position"),)


class StepClosureORM(Base):
    __tablename__ = "step_closures"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    step_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("ot_steps.id"), nullable=False, unique=True)
    actual_duration: Mapped[float] = mapped_column(Numeric(5, 2), nullable=False)
    deviation_key: Mapped[str] = mapped_column(String(30), nullable=False)
    work_description: Mapped[str] = mapped_column(Text, nullable=False)
    safety_question_response: Mapped[bool] = mapped_column(Boolean, nullable=False)
    submitted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())

    step: Mapped["OTStepORM"] = relationship(back_populates="closure")
