from uuid import UUID

from src.domain.models.user import User
from src.domain.ports.user_repository import UserRepository


async def list_technicians(supervisor_id: UUID, user_repo: UserRepository) -> list[User]:
    return await user_repo.list_by_supervisor(supervisor_id)
