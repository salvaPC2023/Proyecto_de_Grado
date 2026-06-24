from datetime import datetime, timezone

from src.domain.models.shift import get_current_shift
from src.domain.models.user import User
from src.domain.models.work_order import TechnicianWorkload
from src.domain.ports.work_order_repository import WorkOrderRepository


async def get_technician_workload(
    supervisor: User,
    work_order_repo: WorkOrderRepository,
) -> list[TechnicianWorkload]:
    shift_number = get_current_shift(datetime.now(timezone.utc))
    return await work_order_repo.get_workload_by_supervisor(supervisor.id, shift_number)
