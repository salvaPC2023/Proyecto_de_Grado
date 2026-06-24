from abc import ABC, abstractmethod
from uuid import UUID

from ..models.user import User, UserStatus


class TechnicianNotFoundError(Exception):
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
    async def list_by_supervisor(self, supervisor_id: UUID) -> list[User]: ...

    @abstractmethod
    async def get_by_id_and_supervisor(self, tech_id: UUID, supervisor_id: UUID) -> User | None: ...
