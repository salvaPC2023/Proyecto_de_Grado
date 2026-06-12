import uuid
from datetime import date, datetime, timezone

from src.domain.models.shift import get_current_shift, SHIFT_WINDOWS
from src.domain.models.work_order import (
    ControlKey, DeviationKey, InstallationState, NoPm01StepError, OTStep,
    OrderType, PlannerGroup, WorkOrder, WorkOrderStatus,
)
from src.domain.models.technical_location import TechnicalLocation
from src.domain.ports.work_order_repository import WorkOrderRepository
from src.domain.ports.technical_location_repository import TechnicalLocationRepository

_FIXED_STEPS = [
    (1, "Piense de manera inteligente", ControlKey.PMNN),
    (2, "Vea, diga, haga algo", ControlKey.PMNN),
    (3, "Se tiene habilidades adecuadas para la tarea", ControlKey.PMNN),
]


async def create_work_order(
    order_type: str,
    technical_location_id: uuid.UUID,
    assigned_technician_id: uuid.UUID,
    created_by_id: uuid.UUID,
    planner_group: str,
    installation_state: str,
    planned_start: date,
    planned_end: date,
    priority: int,
    custom_steps: list[dict],
    work_order_repo: WorkOrderRepository,
    tech_location_repo: TechnicalLocationRepository,
) -> WorkOrder:
    tech_location = await tech_location_repo.get_by_id(technical_location_id)
    if tech_location is None:
        raise ValueError("Technical location not found")

    has_pm01 = any(s.get("control_key") == "PM01" for s in custom_steps)
    if not has_pm01:
        raise NoPm01StepError("At least one PM01 step is required.")

    now = datetime.now(timezone.utc)
    shift_number = get_current_shift(now)

    ot_id = uuid.uuid4()

    steps: list[OTStep] = []
    for pos, desc, ck in _FIXED_STEPS:
        steps.append(OTStep(
            id=uuid.uuid4(),
            work_order_id=ot_id,
            position=pos,
            description=desc,
            control_key=ck,
            is_fixed=True,
        ))

    for i, s in enumerate(custom_steps, start=4):
        ck = ControlKey(s["control_key"])
        pit = s.get("planned_intervention_time")
        if ck == ControlKey.PM01 and (pit is None or pit <= 0):
            raise ValueError(f"Step at position {i}: PM01 steps require planned_intervention_time > 0")
        steps.append(OTStep(
            id=uuid.uuid4(),
            work_order_id=ot_id,
            position=i,
            description=s["description"],
            control_key=ck,
            is_fixed=False,
            planned_intervention_time=float(pit) if pit else None,
        ))

    work_order = WorkOrder(
        id=ot_id,
        order_type=OrderType(order_type),
        technical_location=tech_location,
        assigned_technician_id=assigned_technician_id,
        created_by_id=created_by_id,
        planner_group=PlannerGroup(planner_group),
        activity_class="plant machinery and equipment",
        installation_state=InstallationState(installation_state),
        planned_start=planned_start,
        planned_end=planned_end,
        priority=priority,
        status=WorkOrderStatus.released,
        notif_final=False,
        sin_ttbjo_real=False,
        shift_number=shift_number,
        created_at=now,
        steps=steps,
    )
    return await work_order_repo.create(work_order, steps)
