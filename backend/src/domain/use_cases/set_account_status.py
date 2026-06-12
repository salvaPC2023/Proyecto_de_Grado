from uuid import UUID

from src.domain.models.user import Role, User, UserStatus
from src.domain.ports.user_repository import UserRepository


class CannotDisableSupervisorError(Exception):
    pass


async def set_account_status(
    technician_id: UUID,
    status: UserStatus,
    user_repo: UserRepository,
) -> User:
    user = await user_repo.get_by_id(technician_id)
    if user is None:
        raise ValueError("User not found")
    if user.role == Role.supervisor:
        raise CannotDisableSupervisorError()
    return await user_repo.set_status(technician_id, status)
