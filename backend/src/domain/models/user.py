from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from uuid import UUID


class Role(str, Enum):
    supervisor = "supervisor"
    technician = "technician"


class UserStatus(str, Enum):
    active = "active"
    disabled = "disabled"


@dataclass
class User:
    id: UUID
    username: str
    display_name: str
    password_hash: str
    role: Role
    status: UserStatus
    created_at: datetime
    created_by_id: UUID | None = None
