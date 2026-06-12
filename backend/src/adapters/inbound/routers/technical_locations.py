from uuid import UUID

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from src.adapters.inbound.dependencies import get_current_user, require_supervisor
from src.adapters.outbound.postgres.database import get_session
from src.adapters.outbound.postgres.repositories import PostgresTechnicalLocationRepository
from src.domain.models.user import User
from src.domain.use_cases.get_location_report import get_location_report

router = APIRouter(prefix="/technical-locations", tags=["technical-locations"])


class TechnicalLocationOut(BaseModel):
    id: str
    sector: str
    subsector: str
    system: str
    subsystem: str


class TechnicalLocationReportEntryOut(BaseModel):
    technical_location: TechnicalLocationOut
    ot_count: int


@router.get("", response_model=list[TechnicalLocationOut])
async def list_technical_locations(
    current_user: User = Depends(get_current_user),
    session=Depends(get_session),
):
    repo = PostgresTechnicalLocationRepository(session)
    locations = await repo.list_all()
    return [
        TechnicalLocationOut(id=str(loc.id), sector=loc.sector, subsector=loc.subsector,
                             system=loc.system, subsystem=loc.subsystem)
        for loc in locations
    ]


@router.get("/report", response_model=list[TechnicalLocationReportEntryOut])
async def get_technical_location_report(
    supervisor: User = Depends(require_supervisor),
    session=Depends(get_session),
):
    repo = PostgresTechnicalLocationRepository(session)
    entries = await get_location_report(repo)
    return [
        TechnicalLocationReportEntryOut(
            technical_location=TechnicalLocationOut(
                id=str(e.technical_location.id),
                sector=e.technical_location.sector,
                subsector=e.technical_location.subsector,
                system=e.technical_location.system,
                subsystem=e.technical_location.subsystem,
            ),
            ot_count=e.ot_count,
        )
        for e in entries
    ]
