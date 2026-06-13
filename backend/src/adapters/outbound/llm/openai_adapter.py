import openai

from src.config import settings
from src.domain.ports.standardization_service import (
    StandardizationRequest,
    StandardizationResponse,
    StandardizationServicePort,
    StandardizationTimeoutError,
    StandardizationUnavailableError,
)

_SYSTEM_PROMPT = """Eres un asistente de normalización de órdenes de mantenimiento industrial (PM01).
Reorganiza el texto libre del técnico en las secciones predefinidas que se indican abajo.

REGLAS — debes seguirlas sin excepción:
1. Preserva todos los valores numéricos exactamente como aparecen en el original.
2. Corrige errores tipográficos evidentes en unidades de medida cuando el contexto lo haga inequívoco (ej. "HZz" en un campo de temperatura → "°C").
3. No agregues conclusiones, diagnósticos, recomendaciones ni palabras como "pendiente", "requiere atención" o similares, a menos que el técnico las haya escrito explícitamente.
4. Mantén separados los valores de medición por punto de medición, exactamente como los reportó el técnico — no los fusiones en una sola línea.
5. Omite completamente las secciones que no tengan información en el texto original.
6. Responde ÚNICAMENTE con el texto normalizado en español. Sin explicaciones, saludos ni texto adicional.

FORMATO DE SALIDA (usa solo las secciones que apliquen):

Equipo intervenido: [nombre del equipo o componente]

Actividades realizadas:
- [actividad 1]
- [actividad 2]

Mediciones termográficas:
- [punto de medición 1]: [valor con unidad]
- [punto de medición 2]: [valor con unidad]

Mediciones de vibración:
- [punto de medición 1]: [valor con unidad]
- [punto de medición 2]: [valor con unidad]

Observaciones: [solo hallazgos que el técnico reportó explícitamente, sin agregar interpretaciones]"""


class OpenAIStandardizationAdapter(StandardizationServicePort):

    def __init__(self) -> None:
        self._client = openai.AsyncOpenAI(api_key=settings.OPENAI_API_KEY, timeout=8.0)

    async def standardize(self, request: StandardizationRequest) -> StandardizationResponse:
        try:
            response = await self._client.chat.completions.create(
                model="gpt-4o-mini",
                max_tokens=768,
                messages=[
                    {"role": "system", "content": _SYSTEM_PROMPT},
                    {"role": "user", "content": request.text},
                ],
            )
            standardized_text = response.choices[0].message.content or ""
            return StandardizationResponse(standardized_text=standardized_text)
        except openai.APITimeoutError as exc:
            raise StandardizationTimeoutError("LLM call timed out") from exc
        except openai.RateLimitError as exc:
            raise StandardizationUnavailableError("LLM rate limit exceeded") from exc
        except openai.APIStatusError as exc:
            raise StandardizationUnavailableError(f"LLM API error: {exc.status_code}") from exc
