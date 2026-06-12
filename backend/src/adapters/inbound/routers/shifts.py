from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from src.adapters.inbound.dependencies import get_current_user
from src.domain.models.shift import SHIFT_LABELS, get_current_shift
from src.domain.models.user import User

router = APIRouter(prefix="/shifts", tags=["shifts"])


class CurrentShiftResponse(BaseModel):
    shift_number: int
    start_time: str
    end_time: str
    server_datetime: str


@router.get("/current", response_model=CurrentShiftResponse)
async def get_current_shift_endpoint(current_user: User = Depends(get_current_user)):
    now = datetime.now(timezone.utc)
    shift_number = get_current_shift(now)
    start_time, end_time = SHIFT_LABELS[shift_number]
    return CurrentShiftResponse(
        shift_number=shift_number,
        start_time=start_time,
        end_time=end_time,
        server_datetime=now.isoformat(),
    )
