from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from src.adapters.inbound.jwt_utils import decode_access_token
from src.adapters.outbound.postgres.database import get_session
from src.adapters.outbound.postgres.user_repository import PostgresUserRepository
from src.domain.models.user import Role, User, UserStatus

_bearer = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
    session=Depends(get_session),
) -> User:
    try:
        payload = decode_access_token(credentials.credentials)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated.")

    user_id = UUID(payload["sub"])
    repo = PostgresUserRepository(session)
    user = await repo.get_by_id(user_id)

    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated.")
    if user.status == UserStatus.disabled:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated.")

    return user


async def require_supervisor(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != Role.supervisor:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Supervisor access required.")
    return current_user
