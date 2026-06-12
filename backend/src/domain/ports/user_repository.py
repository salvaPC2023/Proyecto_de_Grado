from abc import ABC, abstractmethod
from uuid import UUID

from ..models.user import User, Role, UserStatus


class TechnicianHasWorkOrdersError(Exception):
    pass


class UserRepository(ABC):

    @abstractmethod
    async def get_by_id(self, user_id: UUID) -> User | None: ...

    @abstractmethod
    async def get_by_username(self, username: str) -> User | None: ...

    @abstractmethod
    async def create(self, user: User) -> User: ...

    @abstractmethod
    async def update_display_name(self, user_id: UUID, display_name: str) -> User: ...

    @abstractmethod
    async def update_username(self, user_id: UUID, username: str) -> User: ...

    @abstractmethod
    async def update_password_hash(self, user_id: UUID, password_hash: str) -> User: ...

    @abstractmethod
    async def set_status(self, user_id: UUID, status: UserStatus) -> User: ...

    @abstractmethod
    async def list_technicians(self) -> list[User]: ...

    @abstractmethod
    async def delete(self, user_id: UUID) -> None: ...
