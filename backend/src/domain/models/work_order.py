from dataclasses import dataclass, field
from datetime import date, datetime
from enum import Enum
from uuid import UUID

from .technical_location import TechnicalLocation


class WorkOrderStatus(str, Enum):
    released = "released"
    notified = "notified"


class ControlKey(str, Enum):
    PMNN = "PMNN"
    PM01 = "PM01"


class DeviationKey(str, Enum):
    executed = "PM01 Executed"
    not_executed = "PM01 Not Executed"


class OrderType(str, Enum):
    OE01 = "OE01"
    OE02 = "OE02"
    OE03 = "OE03"
    OE04 = "OE04"


class PlannerGroup(str, Enum):
    mechanical = "mechanical"
    electrical = "electrical"
    electronic = "electronic"


class InstallationState(str, Enum):
    running = "running"
    stopped = "stopped"


@dataclass
class StepClosure:
    id: UUID
    step_id: UUID
    actual_duration: float
    deviation_key: DeviationKey
    work_description: str
    safety_question_response: bool
    submitted_at: datetime


@dataclass
class OTStep:
    id: UUID
    work_order_id: UUID
    position: int
    description: str
    control_key: ControlKey
    is_fixed: bool
    planned_intervention_time: float | None = None
    closure: StepClosure | None = None


@dataclass
class WorkOrder:
    id: UUID
    order_type: OrderType
    technical_location: TechnicalLocation
    assigned_technician_id: UUID
    created_by_id: UUID
    planner_group: PlannerGroup
    activity_class: str
    installation_state: InstallationState
    planned_start: date
    planned_end: date
    priority: int
    status: WorkOrderStatus
    notif_final: bool
    sin_ttbjo_real: bool
    shift_number: int
    created_at: datetime
    steps: list[OTStep] = field(default_factory=list)


@dataclass
class TechnicianWorkload:
    technician_id: UUID
    technician_name: str
    ot_count: int
    shift_number: int


class NoPm01StepError(Exception):
    pass


class StepAlreadyClosedError(Exception):
    pass


class OtNotAssignedError(Exception):
    pass
