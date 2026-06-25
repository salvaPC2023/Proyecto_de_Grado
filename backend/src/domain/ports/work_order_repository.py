from abc import ABC, abstractmethod
from uuid import UUID

from ..models.work_order import WorkOrder, OTStep, StepClosure, TechnicianWorkload


class WorkOrderRepository(ABC):

    @abstractmethod
    async def create(self, work_order: WorkOrder, steps: list[OTStep]) -> WorkOrder: ...

    @abstractmethod
    async def get_by_id(self, ot_id: UUID) -> WorkOrder | None: ...

    @abstractmethod
    async def list_for_technician_shift(self, technician_id: UUID, shift_number: int) -> list[WorkOrder]: ...

    @abstractmethod
    async def list_for_supervisor_shift(
        self, supervisor_id: UUID, shift_number: int, technician_id: UUID | None = None
    ) -> list[WorkOrder]: ...

    @abstractmethod
    async def get_workload_by_supervisor(
        self, supervisor_id: UUID, shift_number: int
    ) -> list[TechnicianWorkload]: ...

    @abstractmethod
    async def count_unregistered_pm01_steps(self, ot_id: UUID) -> int: ...

    @abstractmethod
    async def add_step_closure(self, closure: StepClosure) -> WorkOrder: ...

    @abstractmethod
    async def set_notified(self, ot_id: UUID) -> WorkOrder: ...
