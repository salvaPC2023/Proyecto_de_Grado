from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, field_validator

from src.adapters.inbound.dependencies import get_current_user
from src.adapters.outbound.llm.openai_adapter import OpenAIStandardizationAdapter
from src.domain.ports.standardization_service import (
    StandardizationTimeoutError,
    StandardizationUnavailableError,
)
from src.domain.use_cases.standardize_description import standardize_description

router = APIRouter(prefix="/descriptions", tags=["descriptions"])


class StandardizationRequestBody(BaseModel):
    text: str

    @field_validator("text")
    @classmethod
    def text_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("El campo 'text' no puede estar vacío.")
        return v


class StandardizationResponseBody(BaseModel):
    standardized_text: str


@router.post("/standardize", response_model=StandardizationResponseBody)
async def standardize_endpoint(
    body: StandardizationRequestBody,
    _current_user=Depends(get_current_user),
):
    service = OpenAIStandardizationAdapter()
    try:
        result = await standardize_description(text=body.text, service=service)
    except StandardizationUnavailableError:
        return JSONResponse(
            status_code=503,
            content={"detail": "El servicio de estandarización no está disponible. Puede enviar su descripción original."},
        )
    except StandardizationTimeoutError:
        return JSONResponse(
            status_code=504,
            content={"detail": "El servicio de estandarización tardó demasiado. Puede enviar su descripción original."},
        )
    return StandardizationResponseBody(standardized_text=result.standardized_text)
