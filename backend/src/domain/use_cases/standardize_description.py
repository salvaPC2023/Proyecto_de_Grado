from src.domain.ports.standardization_service import (
    StandardizationRequest,
    StandardizationResponse,
    StandardizationServicePort,
)


async def standardize_description(
    text: str,
    service: StandardizationServicePort,
) -> StandardizationResponse:
    request = StandardizationRequest(text=text)
    return await service.standardize(request)
