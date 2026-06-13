# Data Model: LLM Description Standardization Module

**Feature**: `003-llm-description-standardization` | **Date**: 2026-06-12

## Overview

This feature introduces **no new database tables or columns**. The final work description
(standardized, edited, or original) is stored in the `work_description` column of the
`ot_steps_closures` table, which already exists from Feature 002. The standardization flow
operates entirely at the application layer through ephemeral objects that are never persisted.

---

## Ephemeral Domain Objects (Not Persisted)

### Backend (Python Dataclasses)

These objects live only for the duration of a single standardization request.

#### `StandardizationRequest`

| Field  | Type  | Constraints              | Description                             |
|--------|-------|--------------------------|-----------------------------------------|
| `text` | `str` | non-empty, max 5 000 chars | The Technician's free-text work description to normalize |

**Validation**: `text` must contain at least one non-whitespace character. Enforced by Pydantic
in the inbound router before the use case is called. Max length matches the existing
`work_description` column constraint from Feature 002.

#### `StandardizationResponse`

| Field                | Type  | Description                                      |
|----------------------|-------|--------------------------------------------------|
| `standardized_text`  | `str` | The normalized description returned by the LLM  |

**Notes**: Not validated beyond being a non-empty string. The Technician is responsible for
reviewing and editing before confirming.

---

### Mobile (Dart Classes)

#### `StandardizationResult`

| Field                | Type     | Description                                      |
|----------------------|----------|--------------------------------------------------|
| `standardizedText`   | `String` | The normalized description returned by the backend |

Used as the success payload of `StandardizationNotifier`'s `AsyncValue<StandardizationResult>`.

---

## Existing Entity: `StepClosure.work_description` (Feature 002 — unchanged)

The `ot_steps_closures` table from Feature 002 stores the final text after the Technician
confirms or skips standardization. No column is added or modified.

| Column             | Type        | Nullable | Notes                                    |
|--------------------|-------------|----------|------------------------------------------|
| `work_description` | `TEXT`      | false    | Stores original OR confirmed standardized text — no distinction |

The Feature 002 contract (`POST /work-orders/{ot_id}/steps/{step_id}/closures`) already
accepts `work_description` as a free string and is not modified by this feature.

---

## Port Interface (Backend Domain)

### `StandardizationServicePort` (Abstract Base Class)

```
StandardizationServicePort
  + standardize(request: StandardizationRequest) -> StandardizationResponse
      raises: StandardizationUnavailableError  # LLM service down or quota exceeded
      raises: StandardizationTimeoutError       # LLM call timed out (> 8 s)
```

The use case `standardize_description` depends on this port. The outbound adapter
`AnthropicStandardizationAdapter` implements it.

---

## Repository Interface (Mobile Domain)

### `StandardizationRepository` (Abstract Dart Class)

```
StandardizationRepository
  + standardize(text: String) -> Future<String>
      throws: StandardizationException  # maps HTTP 503/504 to a typed error
```

`StandardizationRepositoryImpl` implements this by calling `POST /descriptions/standardize`
via Dio and mapping 503 and 504 responses to `StandardizationException`.

---

## State Machine: `StandardizationNotifier` (Mobile ViewModel)

```
           ┌─────────────────────────────────────────────┐
           │         StandardizationNotifier              │
           │    (AsyncNotifier<StandardizationResult?>)   │
           └─────────────────────────────────────────────┘

  State transitions:
  
  initial (null)
    │
    ├─[tap "Standardize description"]──► loading
    │                                       │
    │                             ┌─────────┴──────────┐
    │                             ▼ success             ▼ error
    │                       data(result)          error(exception)
    │                             │                     │
    │                    [tap "Confirm"]       [tap "Retry"]──► loading
    │                    [tap "Keep original"]          │
    │                             │                [dismiss]
    │                             ▼                     ▼
    └──────────────────────── initial (null) ◄──── initial (null)
```

**States**:
- `AsyncValue.loading()`: request in-flight; UI shows loading indicator on the button
- `AsyncValue.data(result)`: success; UI shows standardization panel with editable field
- `AsyncValue.error(exception)`: failure; UI shows non-blocking error message with Retry button
- `null` (initial / dismissed): standardization panel hidden; closure form in normal state
