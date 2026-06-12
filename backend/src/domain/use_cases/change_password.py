from uuid import UUID

from src.domain.ports.user_repository import UserRepository


class WrongPasswordError(Exception):
    pass


async def change_password(
    user_id: UUID,
    current_password: str,
    new_password: str,
    user_repo: UserRepository,
    verify_password,
    hash_password,
) -> None:
    if len(new_password) < 6:
        raise ValueError("New password must be at least 6 characters.")

    user = await user_repo.get_by_id(user_id)
    if not verify_password(current_password, user.password_hash):
        raise WrongPasswordError()

    new_hash = hash_password(new_password)
    await user_repo.update_password_hash(user_id, new_hash)
