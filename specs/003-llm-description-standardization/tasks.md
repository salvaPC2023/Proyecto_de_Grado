# Tasks: LLM Description Standardization Module

**Input**: Design documents from `specs/003-llm-description-standardization/`

**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅

**Tests**: Not requested in spec — no test tasks generated (see plan.md for testing approach).

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

## Path Conventions

This feature extends the existing Mobile + API monorepo:
- Backend: `backend/src/`, `backend/tests/`
- Mobile: `mobile/lib/`, `mobile/test/`

---

## Phase 1: Setup

**Purpose**: Add the new dependency and create the adapter package structure.

- [X] T001 Add `anthropic` Python SDK to `backend/requirements.txt`
- [X] T002 [P] Create `backend/src/adapters/outbound/llm/__init__.py` to establish the LLM adapter package

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain port + ephemeral domain objects needed by BOTH user stories.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 Implement `StandardizationServicePort` ABC + `StandardizationRequest` dataclass + `StandardizationResponse` dataclass + `StandardizationUnavailableError` exception + `StandardizationTimeoutError` exception in `backend/src/domain/ports/standardization_service.py`
- [X] T004 [P] Implement `standardize_description` use case in `backend/src/domain/use_cases/standardize_description.py` — accepts `StandardizationRequest`, calls `StandardizationServicePort.standardize()`, returns `StandardizationResponse`; propagates `StandardizationUnavailableError` and `StandardizationTimeoutError` unchanged
- [X] T005 [P] Define `StandardizationRepository` abstract class with `Future<String> standardize(String text)` + `StandardizationException` typed error class in `mobile/lib/domain/repositories/standardization_repository.dart`

**Checkpoint**: Domain contracts defined on both sides — user story implementation can now begin.

---

## Phase 3: User Story 1 — Technician Standardizes PM01 Closure Description (Priority: P1) 🎯 MVP

**Goal**: Technician taps "Standardize description", sees the LLM-normalized text in an editable
panel, confirms it, and submits the closure with the confirmed text stored in `work_description`.

**Independent Test**: Log in as a Technician on an assigned OT with a PM01 step in `released`
status. Enter a free-text work description, tap "Standardize description" (device online, field
non-empty). Verify loading indicator appears, standardized text panel appears within 10 s,
edit is possible, "Confirm" replaces the field text, closure submits normally. Supervisor views
OT detail and sees the confirmed text.

### Implementation for User Story 1

- [X] T006 [US1] Implement `AnthropicStandardizationAdapter` (success path) in `backend/src/adapters/outbound/llm/anthropic_adapter.py` — instantiate `AsyncAnthropic(timeout=8.0)`, hardcode the Spanish maintenance system prompt (Acción / Componente / Hallazgo / Resultado format), call `messages.create()` with the `text` as the user message, return `StandardizationResponse(standardized_text=response.content[0].text)`
- [X] T007 [US1] Implement `POST /descriptions/standardize` router (success path + 400/401) in `backend/src/adapters/inbound/routers/descriptions.py` — Pydantic `StandardizationRequestBody(text: str, min_length=1, max_length=5000)`, inject `StandardizationServicePort` dependency, call `standardize_description` use case, return `StandardizationResponseBody(standardized_text: str)` with HTTP 200
- [X] T008 [US1] Register `descriptions` router in `backend/src/main.py` under the `/api/v1` prefix
- [X] T009 [P] [US1] Implement `StandardizationRepositoryImpl.standardize()` success path in `mobile/lib/data/remote/standardization_repository_impl.dart` — POST to `/descriptions/standardize` via existing Dio instance, parse `standardized_text` from 200 response, return the string
- [X] T010 [P] [US1] Add `standardizationRepositoryProvider` (override-able Provider) to `mobile/lib/core/di.dart` — returns `StandardizationRepositoryImpl(apiClient: apiClient)`
- [X] T011 [US1] Implement `StandardizationNotifier` (`AsyncNotifier<String?>`) with `standardize(String text)` action in `mobile/lib/presentation/viewmodels/standardization_vm.dart` — transitions: initial (`null`) → loading → `AsyncValue.data(standardizedText)`; `reset()` action returns to initial; `confirm(String text)` action updates the caller's closure form field via callback or return value
- [X] T012 [US1] Implement `StandardizationPanel` widget in `mobile/lib/presentation/widgets/standardization_panel.dart` — shows the standardized text in an editable `TextFormField`, "Confirm" button calls `onConfirm(editedText)`, "Keep original" button calls `onKeepOriginal()`; wraps in a `Card` or `BottomSheet`
- [X] T013 [US1] Integrate into PM01 closure form `mobile/lib/presentation/screens/technician/closure_form_screen.dart` — add "Standardize description" `ElevatedButton` (enabled only when `work_description` field is non-empty AND device is online); watch `standardizationNotifierProvider`; render `StandardizationPanel` when notifier state is `AsyncValue.data`; on confirm → update `work_description` controller text and reset notifier; on keep original → reset notifier

**Checkpoint**: US1 fully demonstrable — Scenario 1 and Scenario 2 from quickstart.md pass.

---

## Phase 4: User Story 2 — Technician Submits Original Description When Standardization Is Unavailable (Priority: P2)

**Goal**: PM01 closure submission is never blocked by standardization failures. The Technician
always has a clear fallback path whether the device is offline, the LLM times out, or the
service returns an error.

**Independent Test**: (a) Enable Airplane Mode on test device → open PM01 closure form → verify
"Standardize description" button is hidden or disabled; submit closure normally. (b) Set
`ANTHROPIC_API_KEY` to an invalid value → tap "Standardize description" → verify non-blocking
error message appears; verify Technician can submit the original description with no extra steps;
verify "Retry" button re-sends the request.

### Implementation for User Story 2

- [X] T014 [US2] Add error handling to `AnthropicStandardizationAdapter` in `backend/src/adapters/outbound/llm/anthropic_adapter.py` — catch `anthropic.APITimeoutError` → raise `StandardizationTimeoutError`; catch `anthropic.RateLimitError` → raise `StandardizationUnavailableError`; catch `anthropic.APIStatusError` (status ≥ 500) → raise `StandardizationUnavailableError`
- [X] T015 [US2] Add 503 and 504 error responses to `POST /descriptions/standardize` router in `backend/src/adapters/inbound/routers/descriptions.py` — catch `StandardizationUnavailableError` → return `JSONResponse(status_code=503, content={"detail": "El servicio de estandarización no está disponible. Puede enviar su descripción original."})` ; catch `StandardizationTimeoutError` → return `JSONResponse(status_code=504, content={"detail": "El servicio de estandarización tardó demasiado. Puede enviar su descripción original."})`
- [X] T016 [US2] Add error handling to `StandardizationRepositoryImpl` in `mobile/lib/data/remote/standardization_repository_impl.dart` — catch `DioException` with status 503 or 504 → throw `StandardizationException("Servicio no disponible")`; catch `DioException` with null response (network error) → throw `StandardizationException("Sin conexión")`
- [X] T017 [US2] Add error state and retry action to `StandardizationNotifier` in `mobile/lib/presentation/viewmodels/standardization_vm.dart` — on `StandardizationException` caught → transition to `AsyncValue.error`; add `retry(String text)` action that re-calls `standardize(text)` from current error state; `reset()` already handles dismiss from error state
- [X] T018 [US2] Add offline detection + error UI to `mobile/lib/presentation/screens/technician/closure_form_screen.dart` — use `connectivity_plus` `connectivityProvider` (already in di.dart from Feature 002) to disable or hide the "Standardize description" button when offline; when notifier is in `AsyncValue.error` state, show a non-blocking `SnackBar` or inline message (e.g., "Estandarización no disponible. Puedes enviar tu descripción original.") with a "Reintentar" button that calls `notifier.retry(text)`; ensure the closure form submit button is always enabled regardless of notifier state

**Checkpoint**: US1 + US2 both functional — Scenarios 3–7 from quickstart.md pass. Closure submission never blocked.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validation and final integration checks.

- [X] T019 [P] Verify `ANTHROPIC_API_KEY` environment variable is documented in Railway deployment guide and in a `.env.example` file at `backend/.env.example`
- [ ] T020 Run quickstart.md API smoke tests (Scenarios 1–7) against the deployed Railway instance and confirm all pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Requires T001 + T002 — BLOCKS all user stories
- **US1 (Phase 3)**: Requires Phase 2 completion — BLOCKS US2 (T014–T018 extend US1 files)
- **US2 (Phase 4)**: Requires Phase 3 completion — T014 and T015 extend the adapter and router from T006/T007; T016 extends impl from T009; T017 extends notifier from T011; T018 extends closure form from T013
- **Polish (Phase 5)**: Requires Phase 4 completion

### Within Each Phase

- T001 before T006 (adapter needs `anthropic` installed)
- T003 before T004 (use case imports port)
- T003 before T006 (adapter implements port)
- T004 before T007 (router calls use case)
- T005 before T009 (impl implements port)
- T006 before T007 (router depends on adapter via DI)
- T009 + T010 before T011 (notifier depends on provider)
- T011 before T012 (panel driven by notifier state)
- T012 before T013 (closure form embeds panel)
- T006 before T014 (error handling added to existing adapter)
- T007 before T015 (error responses added to existing router)
- T009 before T016 (error handling added to existing impl)
- T011 before T017 (error state added to existing notifier)
- T013 before T018 (offline/error UI added to existing screen)

### Parallel Opportunities

Within Phase 2: T004 and T005 can run in parallel after T003 completes
Within Phase 3: T009 and T010 can run in parallel after T005 completes; T007 can start independently of T009/T010

---

## Parallel Example: Phase 3 (User Story 1)

```
After T003 completes:

  [Thread A — Backend]        [Thread B — Mobile]
  T006 AnthropicAdapter       T009 StandardizationRepositoryImpl (success)
  T007 descriptions router    T010 Add provider to di.dart
  T008 Register router
                              ── after T009 + T010 ──
                              T011 StandardizationNotifier
                              T012 StandardizationPanel widget
                              T013 Integrate into closure_form_screen.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003–T005)
3. Complete Phase 3: User Story 1 (T006–T013)
4. **STOP and VALIDATE**: Scenario 1 from quickstart.md — standardization happy path end-to-end
5. Demo to supervisor: tap button → receive normalized text → confirm → submit

### Incremental Delivery

1. Setup + Foundational → contracts and ports defined
2. User Story 1 → standardization works (MVP)
3. User Story 2 → fallback and offline handling added
4. Polish → deployment verification

---

## Notes

- [P] tasks touch different files and have no shared in-progress dependencies
- T014–T018 are additive changes to files already written in Phase 3 — they cannot run in parallel with Phase 3 tasks that touch the same files
- `connectivity_plus` is already a declared dependency from Feature 002; no new package needed
- The closure form submit path (POST /work-orders/{ot_id}/steps/{step_id}/closures) is completely unchanged by this feature
- No database migrations are needed — `work_description` column already exists
