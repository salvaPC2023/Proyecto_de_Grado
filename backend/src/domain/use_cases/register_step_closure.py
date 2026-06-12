import uuid
from datetime import datetime, timezone
from uuid import UUID

from src.domain.models.work_order import (
    ControlKey, DeviationKey, OtNotAssignedError, StepAlreadyClosedError, StepClosure, WorkOrder,
)
from src.domain.ports.work_order_repository import WorkOrderRepository


async def register_step_closure(
    ot_id: UUID,
    step_id: UUID,
    technician_id: UUID,
    actual_duration: float,
    deviation_key: str,
    work_description: str,
    safety_question_response: bool,
    work_order_repo: WorkOrderRepository,
) -> WorkOrder:
    ot = await work_order_repo.get_by_id(ot_id)
    if ot is None:
        raise ValueError("Work Order not found")
    if ot.assigned_technician_id != technician_id:
        raise OtNotAssignedError("This OT is not assigned to you.")

    target_step = next((s for s in ot.steps if s.id == step_id), None)
    if target_step is None:
        raise ValueError("Step not found")
    if target_step.control_key != ControlKey.PM01:
        raise ValueError("Only PM01 steps can have closures")
    if target_step.closure is not None:
        raise StepAlreadyClosedError("This step already has a registered closure.")

    closure = StepClosure(
        id=uuid.uuid4(),
        step_id=step_id,
        actual_duration=actual_duration,
        deviation_key=DeviationKey(deviation_key),
        work_description=work_description,
        safety_question_response=safety_question_response,
        submitted_at=datetime.now(timezone.utc),
    )
    updated_ot = await work_order_repo.add_step_closure(closure)

    remaining = await work_order_repo.count_unregistered_pm01_steps(ot_id)
    if remaining == 0:
        updated_ot = await work_order_repo.set_notified(ot_id)

    return updated_ot
