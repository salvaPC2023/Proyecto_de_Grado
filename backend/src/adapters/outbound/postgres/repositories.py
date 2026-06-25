from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.domain.models.technical_location import TechnicalLocation
from src.domain.models.work_order import (
    ControlKey, DeviationKey, InstallationState, OrderType, OTStep,
    PlannerGroup, StepClosure, TechnicianWorkload, WorkOrder, WorkOrderStatus,
)
from src.domain.ports.technical_location_repository import (
    TechnicalLocationReportEntry, TechnicalLocationRepository,
)
from src.domain.ports.work_order_repository import WorkOrderRepository
from .orm_models import (
    OTStepORM, StepClosureORM, TechnicalLocationORM, UserORM, WorkOrderORM,
)


def _loc_to_domain(row: TechnicalLocationORM) -> TechnicalLocation:
    return TechnicalLocation(
        id=row.id,
        sector=row.sector,
        subsector=row.subsector,
        system=row.system,
        subsystem=row.subsystem,
    )


def _closure_to_domain(row: StepClosureORM) -> StepClosure:
    return StepClosure(
        id=row.id,
        step_id=row.step_id,
        actual_duration=float(row.actual_duration),
        deviation_key=DeviationKey(row.deviation_key),
        work_description=row.work_description,
        safety_question_response=row.safety_question_response,
        submitted_at=row.submitted_at,
    )


def _step_to_domain(row: OTStepORM) -> OTStep:
    return OTStep(
        id=row.id,
        work_order_id=row.work_order_id,
        position=row.position,
        description=row.description,
        control_key=ControlKey(row.control_key),
        is_fixed=row.is_fixed,
        planned_intervention_time=float(row.planned_intervention_time) if row.planned_intervention_time else None,
        closure=_closure_to_domain(row.closure) if row.closure else None,
    )


def _ot_to_domain(row: WorkOrderORM) -> WorkOrder:
    return WorkOrder(
        id=row.id,
        order_type=OrderType(row.order_type),
        technical_location=_loc_to_domain(row.technical_location_rel),
        assigned_technician_id=row.assigned_technician_id,
        created_by_id=row.created_by_id,
        planner_group=PlannerGroup(row.planner_group),
        activity_class=row.activity_class,
        installation_state=InstallationState(row.installation_state),
        planned_start=row.planned_start,
        planned_end=row.planned_end,
        priority=row.priority,
        status=WorkOrderStatus(row.status),
        notif_final=row.notif_final,
        sin_ttbjo_real=row.sin_ttbjo_real,
        shift_number=row.shift_number,
        created_at=row.created_at,
        steps=[_step_to_domain(s) for s in row.steps],
    )


def _ot_query():
    return (
        select(WorkOrderORM)
        .options(
            selectinload(WorkOrderORM.technical_location_rel),
            selectinload(WorkOrderORM.steps).selectinload(OTStepORM.closure),
        )
    )


class PostgresWorkOrderRepository(WorkOrderRepository):
    def __init__(self, session: AsyncSession):
        self._session = session

    async def create(self, work_order: WorkOrder, steps: list[OTStep]) -> WorkOrder:
        ot_orm = WorkOrderORM(
            id=work_order.id,
            order_type=work_order.order_type.value,
            technical_location_id=work_order.technical_location.id,
            assigned_technician_id=work_order.assigned_technician_id,
            created_by_id=work_order.created_by_id,
            planner_group=work_order.planner_group.value,
            activity_class=work_order.activity_class,
            installation_state=work_order.installation_state.value,
            planned_start=work_order.planned_start,
            planned_end=work_order.planned_end,
            priority=work_order.priority,
            status=work_order.status.value,
            notif_final=work_order.notif_final,
            sin_ttbjo_real=work_order.sin_ttbjo_real,
            shift_number=work_order.shift_number,
            created_at=work_order.created_at,
        )
        for s in steps:
            ot_orm.steps.append(OTStepORM(
                id=s.id,
                work_order_id=s.work_order_id,
                position=s.position,
                description=s.description,
                control_key=s.control_key.value,
                planned_intervention_time=s.planned_intervention_time,
                is_fixed=s.is_fixed,
            ))
        self._session.add(ot_orm)
        await self._session.flush()
        result = await self._session.execute(
            _ot_query().where(WorkOrderORM.id == work_order.id)
        )
        return _ot_to_domain(result.scalar_one())

    async def get_by_id(self, ot_id: UUID) -> WorkOrder | None:
        result = await self._session.execute(
            _ot_query().where(WorkOrderORM.id == ot_id)
        )
        row = result.scalar_one_or_none()
        return _ot_to_domain(row) if row else None

    async def list_for_technician_shift(self, technician_id: UUID, shift_number: int) -> list[WorkOrder]:
        result = await self._session.execute(
            _ot_query()
            .where(WorkOrderORM.assigned_technician_id == technician_id)
            .where(WorkOrderORM.shift_number == shift_number)
            .order_by(WorkOrderORM.created_at.desc())
        )
        return [_ot_to_domain(r) for r in result.scalars().all()]

    async def list_for_supervisor_shift(
        self, supervisor_id: UUID, shift_number: int, technician_id: UUID | None = None
    ) -> list[WorkOrder]:
        q = (
            _ot_query()
            .where(WorkOrderORM.shift_number == shift_number)
            .where(WorkOrderORM.created_by_id == supervisor_id)
        )
        if technician_id is not None:
            q = q.where(WorkOrderORM.assigned_technician_id == technician_id)
        result = await self._session.execute(q.order_by(WorkOrderORM.created_at.desc()))
        return [_ot_to_domain(r) for r in result.scalars().all()]

    async def get_workload_by_supervisor(
        self, supervisor_id: UUID, shift_number: int
    ) -> list[TechnicianWorkload]:
        result = await self._session.execute(
            select(
                UserORM.id.label("technician_id"),
                UserORM.display_name.label("technician_name"),
                func.count(WorkOrderORM.id).label("ot_count"),
            )
            .select_from(UserORM)
            .outerjoin(
                WorkOrderORM,
                (WorkOrderORM.assigned_technician_id == UserORM.id)
                & (WorkOrderORM.shift_number == shift_number),
            )
            .where(UserORM.created_by_id == supervisor_id)
            .where(UserORM.role == "technician")
            .group_by(UserORM.id, UserORM.display_name)
            .order_by(func.count(WorkOrderORM.id).desc(), UserORM.display_name.asc())
        )
        return [
            TechnicianWorkload(
                technician_id=row.technician_id,
                technician_name=row.technician_name,
                ot_count=row.ot_count,
                shift_number=shift_number,
            )
            for row in result.all()
        ]

    async def count_unregistered_pm01_steps(self, ot_id: UUID) -> int:
        result = await self._session.execute(
            select(func.count(OTStepORM.id))
            .outerjoin(StepClosureORM, OTStepORM.id == StepClosureORM.step_id)
            .where(OTStepORM.work_order_id == ot_id)
            .where(OTStepORM.control_key == "PM01")
            .where(StepClosureORM.id.is_(None))
        )
        return result.scalar_one()

    async def add_step_closure(self, closure: StepClosure) -> WorkOrder:
        step_row = await self._session.get(OTStepORM, closure.step_id)
        ot_id = step_row.work_order_id
        closure_orm = StepClosureORM(
            id=closure.id,
            step_id=closure.step_id,
            actual_duration=closure.actual_duration,
            deviation_key=closure.deviation_key.value,
            work_description=closure.work_description,
            safety_question_response=closure.safety_question_response,
            submitted_at=closure.submitted_at,
        )
        self._session.add(closure_orm)
        await self._session.flush()
        result = await self._session.execute(
            _ot_query().where(WorkOrderORM.id == ot_id)
        )
        return _ot_to_domain(result.scalar_one())

    async def set_notified(self, ot_id: UUID) -> WorkOrder:
        row = await self._session.get(WorkOrderORM, ot_id)
        row.status = "notified"
        row.notif_final = True
        row.sin_ttbjo_real = True
        await self._session.flush()
        result = await self._session.execute(
            _ot_query().where(WorkOrderORM.id == ot_id)
        )
        return _ot_to_domain(result.scalar_one())


class PostgresTechnicalLocationRepository(TechnicalLocationRepository):
    def __init__(self, session: AsyncSession):
        self._session = session

    async def list_all(self) -> list[TechnicalLocation]:
        result = await self._session.execute(
            select(TechnicalLocationORM).order_by(
                TechnicalLocationORM.sector,
                TechnicalLocationORM.subsector,
                TechnicalLocationORM.system,
                TechnicalLocationORM.subsystem,
            )
        )
        return [_loc_to_domain(r) for r in result.scalars().all()]

    async def get_by_id(self, location_id: UUID) -> TechnicalLocation | None:
        row = await self._session.get(TechnicalLocationORM, location_id)
        return _loc_to_domain(row) if row else None

    async def get_location_report(self, supervisor_id: UUID) -> list[TechnicalLocationReportEntry]:
        result = await self._session.execute(
            select(TechnicalLocationORM, func.count(WorkOrderORM.id).label("ot_count"))
            .outerjoin(
                WorkOrderORM,
                (WorkOrderORM.technical_location_id == TechnicalLocationORM.id)
                & (WorkOrderORM.created_by_id == supervisor_id),
            )
            .group_by(TechnicalLocationORM.id)
            .order_by(func.count(WorkOrderORM.id).desc())
        )
        return [
            TechnicalLocationReportEntry(_loc_to_domain(loc), count)
            for loc, count in result.all()
        ]
