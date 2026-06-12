from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from src.adapters.inbound.dependencies import get_current_user
from src.adapters.inbound.jwt_utils import create_access_token
from src.adapters.inbound.password_utils import verify_password
from src.adapters.outbound.postgres.database import get_session
from src.adapters.outbound.postgres.user_repository import PostgresUserRepository
from src.domain.models.user import User
from src.domain.use_cases.authenticate import (
    AccountDisabledError, InvalidCredentialsError, authenticate,
)

router = APIRouter(prefix="/auth", tags=["auth"])


class LoginRequest(BaseModel):
    username: str
    password: str


class UserSummary(BaseModel):
    id: str
    username: str
    display_name: str
    role: str
    status: str


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserSummary


@router.post("/login", response_model=LoginResponse)
async def login(body: LoginRequest, session=Depends(get_session)):
    repo = PostgresUserRepository(session)
    try:
        user = await authenticate(body.username, body.password, repo, verify_password)
    except InvalidCredentialsError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid username or password.")
    except AccountDisabledError:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="This account has been disabled. Contact your supervisor.")

    token = create_access_token(user.id, user.role.value)
    return LoginResponse(
        access_token=token,
        user=UserSummary(
            id=str(user.id),
            username=user.username,
            display_name=user.display_name,
            role=user.role.value,
            status=user.status.value,
        ),
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(current_user: User = Depends(get_current_user)):
    return None
