import re
from uuid import UUID

from src.domain.models.user import User
from src.domain.ports.user_repository import TechnicianNotFoundError, UserRepository
from .create_technician import UsernameAlreadyExistsError

_USERNAME_RE = re.compile(r"^[a-z0-9_\-\.]{3,50}$")


async def update_technician(
    technician_id: UUID,
    supervisor_id: UUID,
    user_repo: UserRepository,
    display_name: str | None = None,
    username: str | None = None,
) -> User:
    technician = await user_repo.get_by_id_and_supervisor(technician_id, supervisor_id)
    if technician is None:
        raise TechnicianNotFoundError()

    if display_name is not None:
        display_name = display_name.strip()
        if not display_name:
            raise ValueError("display_name must not be empty")
        await user_repo.update_display_name(technician_id, display_name)

    if username is not None:
        username = username.strip().lower()
        if not _USERNAME_RE.match(username):
            raise ValueError("Invalid username format")
        existing = await user_repo.get_by_username(username)
        if existing and existing.id != technician_id:
            raise UsernameAlreadyExistsError(username)
        await user_repo.update_username(technician_id, username)

    return await user_repo.get_by_id(technician_id)
