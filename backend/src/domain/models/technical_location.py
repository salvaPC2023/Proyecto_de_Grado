from dataclasses import dataclass
from uuid import UUID


@dataclass
class TechnicalLocation:
    id: UUID
    sector: str
    subsector: str
    system: str
    subsystem: str
