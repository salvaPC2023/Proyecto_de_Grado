from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from src.adapters.inbound.dependencies import get_current_user, require_supervisor
from src.adapters.inbound.password_utils import hash_password, verify_password
from src.adapters.outbound.postgres.database import get_session
from src.adapters.outbound.postgres.user_repository import PostgresUserRepository
from src.config import settings
from src.domain.models.user import User, UserStatus
from src.domain.use_cases.change_password import WrongPasswordError, change_password
from src.domain.use_cases.create_technician import UsernameAlreadyExistsError, create_technician
from src.domain.use_cases.delete_technician import CannotDeleteSupervisorError, delete_technician
from src.domain.use_cases.list_technicians import list_technicians
from src.domain.use_cases.set_account_status import CannotDisableSupervisorError, set_account_status
from src.domain.use_cases.update_profile import update_profile
from src.domain.use_cases.update_technician import update_technician
from src.domain.ports.user_repository import TechnicianHasWorkOrdersError

router = APIRouter(tags=["users"])


class UserProfile(BaseModel):
    id: str
    username: str
    display_name: str
    role: str
    status: str


class UpdateDisplayNameRequest(BaseModel):
    display_name: str


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


class CreateTechnicianRequest(BaseModel):
    username: str
    display_name: str


class UpdateTechnicianRequest(BaseModel):
    username: str | None = None
    display_name: str | None = None


class SetStatusRequest(BaseModel):
    status: str


def _profile(user: User) -> UserProfile:
    return UserProfile(
        id=str(user.id),
        username=user.username,
        display_name=user.display_name,
        role=user.role.value,
        status=user.status.value,
    )


# ── Own profile ──────────────────────────────────────────────────────────────

@router.get("/users/me", response_model=UserProfile)
async def get_my_profile(current_user: User = Depends(get_current_user)):
    return _profile(current_user)


@router.patch("/users/me", response_model=UserProfile)
async def update_my_display_name(
    body: UpdateDisplayNameRequest,
    current_user: User = Depends(get_current_user),
    session=Depends(get_session),
):
    repo = PostgresUserRepository(session)
    try:
        user = await update_profile(current_user.id, body.display_name, repo)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    await session.commit()
    return _profile(user)


@router.patch("/users/me/password", status_code=status.HTTP_204_NO_CONTENT)
async def change_my_password(
    body: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    session=Depends(get_session),
):
    repo = PostgresUserRepository(session)
    try:
        await change_password(
            current_user.id, body.current_password, body.new_password,
            repo, verify_password, hash_password,
        )
    except WrongPasswordError:
        raise HTTPException(status_code=400, detail="Current password is incorrect.")
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    await session.commit()
    return None


# ── Technician roster (Supervisor only) ──────────────────────────────────────

@router.get("/technicians", response_model=list[UserProfile])
async def get_technicians(supervisor: User = Depends(require_supervisor), session=Depends(get_session)):
    repo = PostgresUserRepository(session)
    users = await list_technicians(repo)
    return [_profile(u) for u in users]


@router.post("/technicians", response_model=UserProfile, status_code=status.HTTP_201_CREATED)
async def create_technician_endpoint(
    body: CreateTechnicianRequest,
    supervisor: User = Depends(require_supervisor),
    session=Depends(get_session),
):
    repo = PostgresUserRepository(session)
    try:
        user = await create_technician(
            body.display_name, body.username, repo,
            hash_password, settings.DEFAULT_TECHNICIAN_PASSWORD, supervisor.id,
        )
    except UsernameAlreadyExistsError as e:
        raise HTTPException(status_code=409, detail=f"Username '{e.username}' is already taken.")
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    await session.commit()
    return _profile(user)


@router.get("/technicians/{tech_id}", response_model=UserProfile)
async def get_technician(
    tech_id: UUID,
    supervisor: User = Depends(require_supervisor),
    session=Depends(get_session),
):
    repo = PostgresUserRepository(session)
    user = await repo.get_by_id(tech_id)
    if user is None:
        raise HTTPException(status_code=404, detail="Technician not found.")
    return _profile(user)


@router.patch("/technicians/{tech_id}", response_model=UserProfile)
async def update_technician_endpoint(
    tech_id: UUID,
    body: UpdateTechnicianRequest,
    supervisor: User = Depends(require_supervisor),
    session=Depends(get_session),
):
    repo = PostgresUserRepository(session)
    try:
        user = await update_technician(tech_id, repo, body.display_name, body.username)
    except UsernameAlreadyExistsError as e:
        raise HTTPException(status_code=409, detail=f"Username '{e.username}' is already taken.")
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    if user is None:
        raise HTTPException(status_code=404, detail="Technician not found.")
    await session.commit()
    return _profile(user)


@router.delete("/technicians/{tech_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_technician_endpoint(
    tech_id: UUID,
    supervisor: User = Depends(require_supervisor),
    session=Depends(get_session),
):
    repo = PostgresUserRepository(session)
    try:
        await delete_technician(tech_id, repo)
    except CannotDeleteSupervisorError:
        raise HTTPException(status_code=400, detail="Supervisor accounts cannot be deleted.")
    except TechnicianHasWorkOrdersError:
        raise HTTPException(
            status_code=409,
            detail="No se puede eliminar un técnico con órdenes de trabajo asignadas.",
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    await session.commit()
    return None


@router.patch("/technicians/{tech_id}/status", response_model=UserProfile)
async def set_technician_status(
    tech_id: UUID,
    body: SetStatusRequest,
    supervisor: User = Depends(require_supervisor),
    session=Depends(get_session),
):
    repo = PostgresUserRepository(session)
    try:
        status_val = UserStatus(body.status)
        user = await set_account_status(tech_id, status_val, repo)
    except CannotDisableSupervisorError:
        raise HTTPException(status_code=400, detail="Supervisor accounts cannot be disabled.")
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    await session.commit()
    return _profile(user)
