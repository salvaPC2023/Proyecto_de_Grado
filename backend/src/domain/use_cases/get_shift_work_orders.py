from datetime import datetime, timezone
from uuid import UUID

from src.domain.models.shift import get_current_shift
from src.domain.models.user import Role, User
from src.domain.models.work_order import WorkOrder
from src.domain.ports.work_order_repository import WorkOrderRepository


async def get_shift_work_orders(
    user: User,
    work_order_repo: WorkOrderRepository,
) -> list[WorkOrder]:
    shift_number = get_current_shift(datetime.now(timezone.utc))
    if user.role == Role.technician:
        return await work_order_repo.list_for_technician_shift(user.id, shift_number)
    return await work_order_repo.list_for_supervisor_shift(shift_number)
