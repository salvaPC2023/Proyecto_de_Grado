from uuid import UUID

from src.domain.models.user import Role
from src.domain.ports.user_repository import UserRepository


class CannotDeleteSupervisorError(Exception):
    pass


async def delete_technician(
    technician_id: UUID,
    user_repo: UserRepository,
) -> None:
    user = await user_repo.get_by_id(technician_id)
    if user is None:
        raise ValueError("Technician not found")
    if user.role == Role.supervisor:
        raise CannotDeleteSupervisorError()
    await user_repo.delete(technician_id)
