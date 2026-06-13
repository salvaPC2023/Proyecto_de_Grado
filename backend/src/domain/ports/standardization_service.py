from abc import ABC, abstractmethod
from dataclasses import dataclass


class StandardizationUnavailableError(Exception):
    pass


class StandardizationTimeoutError(Exception):
    pass


@dataclass
class StandardizationRequest:
    text: str


@dataclass
class StandardizationResponse:
    standardized_text: str


class StandardizationServicePort(ABC):

    @abstractmethod
    async def standardize(self, request: StandardizationRequest) -> StandardizationResponse: ...
