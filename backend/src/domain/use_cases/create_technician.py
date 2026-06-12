import re
import uuid
from datetime import datetime, timezone

from src.domain.models.user import Role, User, UserStatus
from src.domain.ports.user_repository import UserRepository


class UsernameAlreadyExistsError(Exception):
    def __init__(self, username: str):
        self.username = username


_USERNAME_RE = re.compile(r"^[a-z0-9_\-]{3,50}$")


async def create_technician(
    display_name: str,
    username: str,
    user_repo: UserRepository,
    hash_password,
    default_password: str,
    created_by_id: uuid.UUID,
) -> User:
    username = username.strip().lower()
    display_name = display_name.strip()

    if not display_name:
        raise ValueError("display_name must not be empty")
    if not _USERNAME_RE.match(username):
        raise ValueError("username must be 3–50 chars, alphanumeric/underscore/hyphen only")

    existing = await user_repo.get_by_username(username)
    if existing is not None:
        raise UsernameAlreadyExistsError(username)

    user = User(
        id=uuid.uuid4(),
        username=username,
        display_name=display_name,
        password_hash=hash_password(default_password),
        role=Role.technician,
        status=UserStatus.active,
        created_at=datetime.now(timezone.utc),
        created_by_id=created_by_id,
    )
    return await user_repo.create(user)
