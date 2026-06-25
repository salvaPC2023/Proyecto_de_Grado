from uuid import UUID

from src.domain.ports.technical_location_repository import TechnicalLocationRepository, TechnicalLocationReportEntry


async def get_location_report(
    supervisor_id: UUID,
    tech_location_repo: TechnicalLocationRepository,
) -> list[TechnicalLocationReportEntry]:
    return await tech_location_repo.get_location_report(supervisor_id)
