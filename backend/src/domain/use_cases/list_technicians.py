from src.domain.models.user import User
from src.domain.ports.user_repository import UserRepository


async def list_technicians(user_repo: UserRepository) -> list[User]:
    return await user_repo.list_technicians()
