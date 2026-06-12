from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.domain.models.user import Role, User, UserStatus
from src.domain.ports.user_repository import TechnicianHasWorkOrdersError, UserRepository
from .orm_models import UserORM, WorkOrderORM


def _to_domain(row: UserORM) -> User:
    return User(
        id=row.id,
        username=row.username,
        display_name=row.display_name,
        password_hash=row.password_hash,
        role=Role(row.role),
        status=UserStatus(row.status),
        created_at=row.created_at,
        created_by_id=row.created_by_id,
    )


class PostgresUserRepository(UserRepository):
    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_by_id(self, user_id: UUID) -> User | None:
        row = await self._session.get(UserORM, user_id)
        return _to_domain(row) if row else None

    async def get_by_username(self, username: str) -> User | None:
        result = await self._session.execute(
            select(UserORM).where(UserORM.username == username.lower())
        )
        row = result.scalar_one_or_none()
        return _to_domain(row) if row else None

    async def create(self, user: User) -> User:
        row = UserORM(
            id=user.id,
            username=user.username,
            display_name=user.display_name,
            password_hash=user.password_hash,
            role=user.role.value,
            status=user.status.value,
            created_at=user.created_at,
            created_by_id=user.created_by_id,
        )
        self._session.add(row)
        await self._session.flush()
        await self._session.refresh(row)
        return _to_domain(row)

    async def update_display_name(self, user_id: UUID, display_name: str) -> User:
        row = await self._session.get(UserORM, user_id)
        row.display_name = display_name
        await self._session.flush()
        return _to_domain(row)

    async def update_username(self, user_id: UUID, username: str) -> User:
        row = await self._session.get(UserORM, user_id)
        row.username = username.lower()
        await self._session.flush()
        return _to_domain(row)

    async def update_password_hash(self, user_id: UUID, password_hash: str) -> User:
        row = await self._session.get(UserORM, user_id)
        row.password_hash = password_hash
        await self._session.flush()
        return _to_domain(row)

    async def set_status(self, user_id: UUID, status: UserStatus) -> User:
        row = await self._session.get(UserORM, user_id)
        row.status = status.value
        await self._session.flush()
        return _to_domain(row)

    async def list_technicians(self) -> list[User]:
        result = await self._session.execute(
            select(UserORM).where(UserORM.role == Role.technician.value).order_by(UserORM.display_name)
        )
        return [_to_domain(r) for r in result.scalars().all()]

    async def delete(self, user_id: UUID) -> None:
        has_ots = await self._session.execute(
            select(WorkOrderORM.id)
            .where(WorkOrderORM.assigned_technician_id == user_id)
            .limit(1)
        )
        if has_ots.scalar_one_or_none() is not None:
            raise TechnicianHasWorkOrdersError()
        row = await self._session.get(UserORM, user_id)
        if row:
            await self._session.delete(row)
            await self._session.flush()
