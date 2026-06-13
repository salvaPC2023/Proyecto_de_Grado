# Research: LLM Description Standardization Module

**Feature**: `003-llm-description-standardization` | **Date**: 2026-06-12

## Decision 1: LLM Provider — Anthropic Claude (claude-haiku-4-5)

**Decision**: Use Anthropic Claude via the `anthropic` Python SDK; model `claude-haiku-4-5`
(or equivalent cheapest-available Haiku-tier model).

**Rationale**:
- Project constitution already lists Anthropic as the primary LLM provider
- `claude-haiku-4-5` offers the lowest latency and cost in the Claude family — well within
  the 8-second backend timeout budget
- Strong Spanish-language comprehension confirmed by Anthropic documentation
- Python SDK (`anthropic`) is well-documented, typed, and integrates cleanly with `asyncio`
  via `AsyncAnthropic`
- Single dependency addition to `requirements.txt`; no new infrastructure

**Alternatives considered**:
- OpenAI `gpt-4o-mini`: equally strong Spanish support, similar cost, also acceptable; not
  chosen because the constitution lists Anthropic first and using two LLM SDKs would violate
  Simplicity (V)
- Self-hosted open-source model (e.g., Mistral 7B on Railway): free but requires GPU or
  multi-instance Railway setup; violates Simplicity (V) for thesis scope

---

## Decision 2: API Endpoint Design — Flat Resource `POST /descriptions/standardize`

**Decision**: A single flat endpoint `POST /descriptions/standardize` that accepts the
Technician's text and returns the standardized version. The OT ID is not required as a
parameter.

**Rationale**:
- Standardization is a stateless transformation applied to a string of text; it has no
  dependency on a specific OT or step
- The mobile calls this endpoint before the closure is committed — there is no step closure
  record yet at standardization time, so nesting under `/work-orders/{ot_id}/steps/{step_id}`
  would be semantically incorrect
- Flat resource keeps the router and use case simple; only text input → text output

**Alternatives considered**:
- `POST /work-orders/{ot_id}/steps/{step_id}/standardize`: conceptually tied to a step, but
  requires a valid step ID at call time (which doesn't exist until after submission); rejected
- Sending OT context (type, location) alongside the text to improve prompt quality: valuable
  but deferred — the system prompt can describe the maintenance domain generally without
  per-request OT metadata; scope creep risk for thesis timeline

---

## Decision 3: Backend Timeout — 8 Seconds on the Anthropic SDK Call

**Decision**: Set `timeout=8.0` on the `AsyncAnthropic` client. On `anthropic.APITimeoutError`
or `asyncio.TimeoutError`, the FastAPI router returns HTTP 504 Gateway Timeout.

**Rationale**:
- SC-001 requires the total round-trip (mobile tap → Anthropic → mobile display) within 10 s
- 8 s for the LLM call leaves ~2 s for network and FastAPI overhead, which is adequate for
  Railway deployments
- The Anthropic SDK raises `APITimeoutError` natively when the configured timeout elapses;
  no manual `asyncio.wait_for` wrapper needed

**Alternatives considered**:
- 5 s: Too tight for `claude-haiku-4-5` under quota-throttled conditions; would cause false
  timeouts under mild load
- 15 s: Exceeds the SC-001 budget; unacceptable UX
- Per-request configurable timeout: rejected — Simplicity (V); one value is sufficient

---

## Decision 4: System Prompt — Hardcoded in the Anthropic Adapter

**Decision**: A fixed Spanish-language system prompt is hardcoded as a constant in
`anthropic_adapter.py`. The prompt instructs Claude to normalize the maintenance work
description into a structured format: **Acción** + **Componente** + **Hallazgo** +
**Resultado**. Only the Technician's text is variable (passed as the `user` message).

**Example system prompt**:
```
Eres un asistente de mantenimiento industrial. Tu tarea es normalizar la descripción de
trabajo de una orden PM01 en el siguiente formato estructurado:

Acción: [qué se hizo]
Componente: [en qué parte o equipo]
Hallazgo: [qué condición se encontró]
Resultado: [qué quedó operativo o pendiente]

Responde ÚNICAMENTE con la descripción normalizada en español. No incluyas explicaciones,
saludos ni texto adicional.
```

**Rationale**:
- Simplicity (V): configurable prompts would require a configuration API, a UI, and input
  validation — all out of scope for thesis
- The structured format (Acción/Componente/Hallazgo/Resultado) maps directly to the four
  data points supervisors need when reading closure records
- Hardcoded prompt is easier to test (deterministic input to the adapter mock)

**Alternatives considered**:
- DB-stored configurable prompt: deferred; over-engineering for current scope
- No system prompt (rely on user message framing only): less reliable structure; rejected

---

## Decision 5: Retry Policy — User-Triggered Retry Only (No Backend Auto-Retry)

**Decision**: The backend makes exactly one Anthropic API call per request. On failure, it
returns an error HTTP code. The mobile shows a "Retry" button that re-sends the full request.
No exponential backoff or automatic retry on the backend.

**Rationale**:
- Simplicity (V): auto-retry logic adds complexity with marginal benefit
- Rate-limit errors (429 from Anthropic) do not resolve within the time a retry would occur;
  auto-retry would simply produce a second failure and delay the error message
- User-triggered retry is transparent: the Technician sees the failure immediately and decides
  whether to retry or proceed with the original text

**Alternatives considered**:
- 1 automatic retry with 1 s backoff: adds ~1 s delay to every timeout and does not help
  with quota errors; rejected
- Circuit breaker pattern: over-engineering for thesis scale; rejected

---

## Decision 6: Error HTTP Codes

**Decision**:
- `503 Service Unavailable` — Anthropic API is down, returned an error, or quota exceeded
  (maps to `anthropic.APIStatusError` with status ≥ 500, or `anthropic.RateLimitError`)
- `504 Gateway Timeout` — Anthropic SDK call timed out (`anthropic.APITimeoutError`)
- `400 Bad Request` — request body has empty `text` field (validated by Pydantic before
  reaching the use case)

**Rationale**:
- Semantic clarity: mobile can branch on 503 vs 504 to display slightly different messages
  ("servicio no disponible" vs "tiempo de espera agotado") if desired
- 503 and 504 are the standard HTTP codes for upstream failures and timeout respectively;
  no custom error taxonomy needed

**Alternatives considered**:
- All upstream errors as 500 Internal Server Error: rejected — too generic; hides the
  distinction between a configuration error and a transient availability issue

---

## Decision 7: Offline Detection — `connectivity_plus` on Mobile (Already Available)

**Decision**: The mobile uses the `connectivity_plus` package (already a dependency from
Feature 002's offline closure queue) to hide the "Standardize description" button when the
device reports no network connectivity.

**Rationale**:
- Reuses an existing dependency; no new package addition
- FR-007 requires the button to be hidden or disabled when offline — checking connectivity
  before rendering is simpler than attempting the request and handling the error
- Hides the button proactively: better UX than showing the button and then surfacing an error

**Alternatives considered**:
- Attempt the request and catch a network error: worse UX (extra tap, then error); not hiding
  the button contradicts FR-007; rejected

---

## Decision 8: Data Flow — Confirmed Text Replaces Field; Existing Closure Endpoint Unchanged

**Decision**: After the Technician confirms a standardized (or standardized-then-edited) text,
the mobile simply updates the local `work_description` field in the PM01 closure form with the
confirmed string. The closure is then submitted via the existing
`POST /work-orders/{ot_id}/steps/{step_id}/closures` endpoint from Feature 002 — unchanged.
No new submission endpoint is added. No "was_standardized" flag is stored.

**Rationale**:
- The existing closure endpoint already accepts `work_description` as a free string; it is
  agnostic to whether the text was standardized or not
- FR-011 and FR-012 explicitly require no secondary field to distinguish standardized from
  original descriptions
- Zero schema changes; no migration; no new API endpoint for the submission path

**Alternatives considered**:
- New `POST /work-orders/{ot_id}/steps/{step_id}/closures/standardized` endpoint: rejected —
  unnecessary duplication; violates Simplicity (V)
- Store `was_standardized: bool` in the closure record: explicitly rejected by FR-011
