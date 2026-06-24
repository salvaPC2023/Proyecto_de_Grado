from uuid import UUID

from src.domain.models.user import Role, User, UserStatus
from src.domain.ports.user_repository import TechnicianNotFoundError, UserRepository


class CannotDisableSupervisorError(Exception):
    pass


async def set_account_status(
    technician_id: UUID,
    supervisor_id: UUID,
    status: UserStatus,
    user_repo: UserRepository,
) -> User:
    technician = await user_repo.get_by_id_and_supervisor(technician_id, supervisor_id)
    if technician is None:
        raise TechnicianNotFoundError()
    if technician.role == Role.supervisor:
        raise CannotDisableSupervisorError()
    return await user_repo.set_status(technician_id, status)
