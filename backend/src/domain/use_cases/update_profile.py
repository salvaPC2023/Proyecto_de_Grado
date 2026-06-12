from uuid import UUID

from src.domain.models.user import User
from src.domain.ports.user_repository import UserRepository


async def update_profile(
    user_id: UUID,
    display_name: str,
    user_repo: UserRepository,
) -> User:
    display_name = display_name.strip()
    if not display_name:
        raise ValueError("display_name must not be empty")
    return await user_repo.update_display_name(user_id, display_name)
