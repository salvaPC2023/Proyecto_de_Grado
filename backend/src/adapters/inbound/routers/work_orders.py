from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from src.adapters.inbound.dependencies import get_current_user, require_supervisor
from src.adapters.outbound.postgres.database import get_session
from src.adapters.outbound.postgres.repositories import (
    PostgresTechnicalLocationRepository, PostgresWorkOrderRepository,
)
from src.domain.models.user import Role, User
from src.domain.models.work_order import (
    NoPm01StepError, OtNotAssignedError, StepAlreadyClosedError, WorkOrder,
)
from src.domain.use_cases.create_work_order import create_work_order
from src.domain.use_cases.get_shift_work_orders import get_shift_work_orders
from src.domain.use_cases.register_step_closure import register_step_closure

router = APIRouter(prefix="/work-orders", tags=["work-orders"])


# ── Pydantic schemas ─────────────────────────────────────────────────────────

class CreateStepRequest(BaseModel):
    description: str
    control_key: str
    planned_intervention_time: float | None = None


class CreateWorkOrderRequest(BaseModel):
    order_type: str
    technical_location_id: UUID
    assigned_technician_id: UUID
    planner_group: str
    installation_state: str
    planned_start: date
    planned_end: date
    priority: int
    steps: list[CreateStepRequest]


class TechnicalLocationOut(BaseModel):
    id: str
    sector: str
    subsector: str
    system: str
    subsystem: str


class StepClosureDetailOut(BaseModel):
    id: str
    actual_duration: float
    deviation_key: str
    work_description: str
    safety_question_response: bool
    submitted_at: str


class OTStepDetailOut(BaseModel):
    id: str
    position: int
    description: str
    control_key: str
    planned_intervention_time: float | None = None
    is_fixed: bool
    closure: StepClosureDetailOut | None = None


class WorkOrderSummaryOut(BaseModel):
    id: str
    order_type: str
    technical_location: TechnicalLocationOut
    assigned_technician_id: str
    priority: int
    planned_start: str
    planned_end: str
    status: str
    shift_number: int


class WorkOrderDetailOut(BaseModel):
    id: str
    order_type: str
    technical_location: TechnicalLocationOut
    assigned_technician_id: str
    created_by_id: str
    planner_group: str
    activity_class: str
    installation_state: str
    planned_start: str
    planned_end: str
    priority: int
    status: str
    notif_final: bool
    sin_ttbjo_real: bool
    shift_number: int
    created_at: str
    steps: list[OTStepDetailOut]


class RegisterClosureRequest(BaseModel):
    actual_duration: float
    deviation_key: str
    work_description: str
    safety_question_response: bool


def _loc_out(loc) -> TechnicalLocationOut:
    return TechnicalLocationOut(id=str(loc.id), sector=loc.sector, subsector=loc.subsector,
                                system=loc.system, subsystem=loc.subsystem)


def _step_out(step) -> OTStepDetailOut:
    closure_out = None
    if step.closure:
        c = step.closure
        closure_out = StepClosureDetailOut(
            id=str(c.id),
            actual_duration=c.actual_duration,
            deviation_key=c.deviation_key.value,
            work_description=c.work_description,
            safety_question_response=c.safety_question_response,
            submitted_at=c.submitted_at.isoformat(),
        )
    return OTStepDetailOut(
        id=str(step.id),
        position=step.position,
        description=step.description,
        control_key=step.control_key.value,
        planned_intervention_time=step.planned_intervention_time,
        is_fixed=step.is_fixed,
        closure=closure_out,
    )


def _detail_out(ot: WorkOrder) -> WorkOrderDetailOut:
    return WorkOrderDetailOut(
        id=str(ot.id),
        order_type=ot.order_type.value,
        technical_location=_loc_out(ot.technical_location),
        assigned_technician_id=str(ot.assigned_technician_id),
        created_by_id=str(ot.created_by_id),
        planner_group=ot.planner_group.value,
        activity_class=ot.activity_class,
        installation_state=ot.installation_state.value,
        planned_start=ot.planned_start.isoformat(),
        planned_end=ot.planned_end.isoformat(),
        priority=ot.priority,
        status=ot.status.value,
        notif_final=ot.notif_final,
        sin_ttbjo_real=ot.sin_ttbjo_real,
        shift_number=ot.shift_number,
        created_at=ot.created_at.isoformat(),
        steps=[_step_out(s) for s in ot.steps],
    )


def _summary_out(ot: WorkOrder) -> WorkOrderSummaryOut:
    return WorkOrderSummaryOut(
        id=str(ot.id),
        order_type=ot.order_type.value,
        technical_location=_loc_out(ot.technical_location),
        assigned_technician_id=str(ot.assigned_technician_id),
        priority=ot.priority,
        planned_start=ot.planned_start.isoformat(),
        planned_end=ot.planned_end.isoformat(),
        status=ot.status.value,
        shift_number=ot.shift_number,
    )


# ── Endpoints ────────────────────────────────────────────────────────────────

@router.post("", response_model=WorkOrderDetailOut, status_code=status.HTTP_201_CREATED)
async def create_work_order_endpoint(
    body: CreateWorkOrderRequest,
    supervisor: User = Depends(require_supervisor),
    session=Depends(get_session),
):
    wo_repo = PostgresWorkOrderRepository(session)
    loc_repo = PostgresTechnicalLocationRepository(session)
    try:
        ot = await create_work_order(
            order_type=body.order_type,
            technical_location_id=body.technical_location_id,
            assigned_technician_id=body.assigned_technician_id,
            created_by_id=supervisor.id,
            planner_group=body.planner_group,
            installation_state=body.installation_state,
            planned_start=body.planned_start,
            planned_end=body.planned_end,
            priority=body.priority,
            custom_steps=[s.model_dump() for s in body.steps],
            work_order_repo=wo_repo,
            tech_location_repo=loc_repo,
        )
    except NoPm01StepError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    await session.commit()
    return _detail_out(ot)


@router.get("", response_model=list[WorkOrderSummaryOut])
async def list_work_orders(
    current_user: User = Depends(get_current_user),
    session=Depends(get_session),
):
    wo_repo = PostgresWorkOrderRepository(session)
    ots = await get_shift_work_orders(current_user, wo_repo)
    return [_summary_out(ot) for ot in ots]


@router.get("/{ot_id}", response_model=WorkOrderDetailOut)
async def get_work_order(
    ot_id: UUID,
    current_user: User = Depends(get_current_user),
    session=Depends(get_session),
):
    wo_repo = PostgresWorkOrderRepository(session)
    ot = await wo_repo.get_by_id(ot_id)
    if ot is None:
        raise HTTPException(status_code=404, detail="Work Order not found.")
    if current_user.role == Role.technician and ot.assigned_technician_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied.")
    return _detail_out(ot)


@router.post("/{ot_id}/steps/{step_id}/closures", response_model=WorkOrderDetailOut, status_code=status.HTTP_201_CREATED)
async def register_closure(
    ot_id: UUID,
    step_id: UUID,
    body: RegisterClosureRequest,
    current_user: User = Depends(get_current_user),
    session=Depends(get_session),
):
    if current_user.role == Role.supervisor:
        raise HTTPException(status_code=403, detail="Only Technicians can register closures.")
    wo_repo = PostgresWorkOrderRepository(session)
    try:
        ot = await register_step_closure(
            ot_id=ot_id,
            step_id=step_id,
            technician_id=current_user.id,
            actual_duration=body.actual_duration,
            deviation_key=body.deviation_key,
            work_description=body.work_description,
            safety_question_response=body.safety_question_response,
            work_order_repo=wo_repo,
        )
    except StepAlreadyClosedError as e:
        raise HTTPException(status_code=409, detail=str(e))
    except OtNotAssignedError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    await session.commit()
    return _detail_out(ot)
