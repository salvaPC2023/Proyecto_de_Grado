from src.domain.models.user import User, UserStatus
from src.domain.ports.user_repository import UserRepository


class InvalidCredentialsError(Exception):
    pass


class AccountDisabledError(Exception):
    pass


async def authenticate(
    username: str,
    password: str,
    user_repo: UserRepository,
    verify_password,
) -> User:
    user = await user_repo.get_by_username(username.lower())
    if user is None or not verify_password(password, user.password_hash):
        raise InvalidCredentialsError()
    if user.status == UserStatus.disabled:
        raise AccountDisabledError()
    return user
