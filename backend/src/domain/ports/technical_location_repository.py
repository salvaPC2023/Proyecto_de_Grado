from abc import ABC, abstractmethod
from uuid import UUID

from ..models.technical_location import TechnicalLocation


class TechnicalLocationReportEntry:
    def __init__(self, technical_location: TechnicalLocation, ot_count: int):
        self.technical_location = technical_location
        self.ot_count = ot_count


class TechnicalLocationRepository(ABC):

    @abstractmethod
    async def list_all(self) -> list[TechnicalLocation]: ...

    @abstractmethod
    async def get_by_id(self, location_id: UUID) -> TechnicalLocation | None: ...

    @abstractmethod
    async def get_location_report(self, supervisor_id: UUID) -> list[TechnicalLocationReportEntry]: ...
