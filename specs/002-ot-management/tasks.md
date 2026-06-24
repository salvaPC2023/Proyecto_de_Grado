---
description: "Task list for OT Management Module implementation"
---

# Tasks: OT Management Module

**Input**: Design documents from `specs/002-ot-management/`

**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Feature 001 prerequisite**: All tasks in `specs/001-user-management/tasks.md` complete
and verified. This feature reuses the backend project skeleton, Alembic config, Dio
`ApiClient`, `TokenStorage`, go_router scaffold, and `di.dart` from feature 001.

**Tests**: Not requested — test tasks omitted per project constitution.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: Which user story this task belongs to (US1–US6)
- All descriptions include exact file paths

---

## Phase 1: Setup (Feature 002 Specific)

**Purpose**: Database schema and mobile constants. No new project initialization needed
(feature 001 already initialised the backend and mobile projects).

- [X] T001 Create Alembic migration `002_create_ot_tables.py` in `backend/alembic/versions/`: create tables `technical_locations`, `work_orders`, `ot_steps`, `step_closures` with all columns, FKs, UNIQUE constraints, and indexes from data-model.md
- [X] T002 [P] Create Alembic seed migration `003_seed_technical_locations.py` in `backend/alembic/versions/` with at least 5 representative technical location leaf nodes (sector/subsector/system/subsystem) as sample data
- [X] T003 [P] Create `get_current_shift(dt: datetime) -> int` pure function and `SHIFT_WINDOWS` constant dict in `backend/src/domain/models/shift.py`; no SQLAlchemy imports; timezone-aware using `SERVER_TIMEZONE` env var
- [X] T004 [P] Create `mobile/lib/core/constants.dart` with: shift window definitions, deviation key labels ('PM01 Executed', 'PM01 Not Executed'), fixed step descriptions (3 PMNN safety step strings), priority label map (1–4)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: All domain models, ports, ORM models, repositories, and mobile infrastructure
that MUST exist before any user story can be implemented.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Backend Domain

- [X] T005 Create `WorkOrder`, `OTStep`, `StepClosure` Python dataclasses (no SQLAlchemy imports) with all fields from data-model.md; add `WorkOrderStatus`, `ControlKey`, `DeviationKey` string-enum classes in `backend/src/domain/models/work_order.py`
- [X] T006 [P] Create `TechnicalLocation` Python dataclass in `backend/src/domain/models/technical_location.py`
- [X] T007 [P] Create abstract `WorkOrderRepository` port with async methods: `create`, `get_by_id`, `list_for_technician_shift`, `list_for_supervisor_shift`, `count_unregistered_pm01_steps`, `add_step_closure`, `set_notified` in `backend/src/domain/ports/work_order_repository.py`
- [X] T008 [P] Create abstract `TechnicalLocationRepository` port with async methods: `list_all`, `get_by_id`, `get_location_report` in `backend/src/domain/ports/technical_location_repository.py`
- [X] T009 Add `WorkOrderORM`, `OTStepORM`, `StepClosureORM`, `TechnicalLocationORM` SQLAlchemy mapped classes to `backend/src/adapters/outbound/postgres/orm_models.py` (extend the existing file from feature 001)
- [X] T010 Implement `PostgresWorkOrderRepository` and `PostgresTechnicalLocationRepository` in `backend/src/adapters/outbound/postgres/repositories.py` implementing all port methods using `AsyncSession` and the new ORM models

### Mobile Domain & Infrastructure

- [X] T011 [P] Create `WorkOrder`, `WorkOrderStatus`, `OTStep`, `ControlKey`, `StepClosure`, `DeviationKey`, `SyncStatus`, `PendingClosure` pure Dart classes in `mobile/lib/domain/models/work_order.dart`, `mobile/lib/domain/models/ot_step.dart`, `mobile/lib/domain/models/step_closure.dart`
- [X] T012 [P] Create `TechnicalLocation` and `TechnicalLocationReportEntry` pure Dart classes in `mobile/lib/domain/models/technical_location.dart`
- [X] T013 [P] Create Drift `AppDatabase` with three table definitions: `PendingClosures`, `CachedWorkOrders`, `CachedOtSteps` (columns from data-model.md), and `@DriftDatabase` annotation; run `build_runner` to generate the `.g.dart` file in `mobile/lib/data/local/database.dart`
- [X] T014 [P] Create `PendingClosureDao` with methods `insertPending`, `listPending`, `markSynced`, `markFailed`, `deleteSynced` in `mobile/lib/data/local/daos/pending_closure_dao.dart`
- [X] T015 [P] Create `CachedWorkOrderDao` with methods `upsertAll`, `listCached`, `upsertSteps`, `listStepsFor` in `mobile/lib/data/local/daos/cached_work_order_dao.dart`
- [X] T016 [P] Create `WorkOrderSummaryDto`, `WorkOrderDetailDto`, `OTStepDetailDto` Dart classes with `fromJson` factories in `mobile/lib/data/remote/dtos/work_order_dto.dart`
- [X] T017 [P] Create `RegisterClosureRequest`, `StepClosureDetailDto`, `TechnicalLocationDto`, `TechnicalLocationReportEntryDto` Dart classes with `fromJson`/`toJson` in `mobile/lib/data/remote/dtos/closure_dto.dart`
- [X] T018 [P] Create abstract `WorkOrderRepository` interface with `listForShift`, `getById`, `createWorkOrder`, `registerClosure` in `mobile/lib/domain/repositories/work_order_repository.dart`
- [X] T019 [P] Create abstract `SyncRepository` interface with `syncPending`, `pendingCount` in `mobile/lib/domain/repositories/sync_repository.dart`
- [X] T020 [P] Create abstract `TechnicalLocationRepository` interface with `listLocations`, `getLocationReport` in `mobile/lib/domain/repositories/technical_location_repository.dart`

**Checkpoint**: Foundation ready — all user story implementation can begin in parallel

---

## Phase 3: User Story 1 — Supervisor Creates Work Order (Priority: P1) 🎯 MVP

**Goal**: Supervisor fills the create OT form (all required fields + step list with at
least one PM01 step) and the OT is saved with status Released, assigned to a Technician.

**Independent Test**: See `quickstart.md` Story 1 section — create OT with all fields,
verify 3 fixed PMNN steps are prepended, verify submission rejected when no PM01 step.

### Backend — US1

- [X] T021 [P] [US1] Implement `create_work_order` use case: inject 3 fixed PMNN steps at positions 1–3 using `SHIFT_WINDOWS` and constants, append custom steps at positions 4+, reject if no PM01 step exists, reject if PM01 step has no `planned_intervention_time`, compute `shift_number` via `get_current_shift`, persist OT + steps in one transaction in `backend/src/domain/use_cases/create_work_order.py`
- [X] T022 [US1] Implement `POST /api/v1/work-orders` router using `create_work_order` use case with `require_supervisor` dependency; return HTTP 201 `WorkOrderDetail`; map `NoPm01StepError` → HTTP 400; register router in `backend/src/main.py` in `backend/src/adapters/inbound/routers/work_orders.py`
- [X] T023 [P] [US1] Implement `GET /api/v1/technical-locations` router listing all locations (both roles); register in `backend/src/main.py` in `backend/src/adapters/inbound/routers/technical_locations.py`
- [X] T024 [P] [US1] Implement `GET /api/v1/shifts/current` router returning current shift number + window + server datetime (both roles); register in `backend/src/main.py` in `backend/src/adapters/inbound/routers/shifts.py`

### Mobile — US1

- [X] T025 [P] [US1] Implement `TechnicalLocationRepositoryImpl` with `listLocations()` calling `GET /api/v1/technical-locations` via Dio client in `mobile/lib/data/remote/technical_location_repository_impl.dart`
- [X] T026 [P] [US1] Implement `WorkOrderRepositoryImpl` with `createWorkOrder(request)` calling `POST /api/v1/work-orders` via Dio client; parse `WorkOrderDetailDto` response in `mobile/lib/data/remote/work_order_repository_impl.dart`
- [X] T027 [US1] Create `SupervisorDashboardNotifier` skeleton as `AsyncNotifier<List<WorkOrder>>` with `createWorkOrder(CreateWorkOrderRequest)` action wired to `WorkOrderRepositoryImpl.createWorkOrder`; `state` is an empty-list stub for now (shift-list loading is added in T045) in `mobile/lib/presentation/viewmodels/supervisor_dashboard_vm.dart`
- [X] T028 [US1] Implement `CreateWorkOrderScreen`: selectors for all required fields (order type chips, drill-down technical location picker grouping the flat `listLocations()` result by sector→subsector→system→subsystem, assigned technician dropdown using existing user list endpoint, planner group, installation state, date pickers, priority — **`activity_class` is pre-filled by the use case to `'plant machinery and equipment'` and MUST NOT appear as a form selector**), step list section (3 pre-rendered read-only PMNN cards + "Add Step" button for PM01/PMNN custom steps with planned time field for PM01), client-side validation, submit wired to `SupervisorDashboardNotifier.createWorkOrder`, loading state in `mobile/lib/presentation/screens/supervisor/create_work_order_screen.dart`
- [X] T029 [US1] Add `/supervisor/create-work-order` route to go_router (Supervisor only); add `technicianListProvider`, `techLocRepositoryProvider`, and `supervisorDashboardProvider` to `mobile/lib/core/di.dart`

**Checkpoint**: US1 complete — Supervisor creates OT with fixed safety steps; OT appears as Released and assigned to Technician

---

## Phase 4: User Story 2 — Technician Views Assigned Work Orders (Priority: P2)

**Goal**: Technician sees only their own current-shift OTs in a list and can open any OT
for full detail with the complete ordered step list.

**Independent Test**: See `quickstart.md` Story 2 section — verify OT list shows only
assigned OTs, detail shows all fields and steps with correct control-key indicators.

### Backend — US2

- [X] T030 [P] [US2] Implement `get_shift_work_orders(user, work_order_repo, shift_fn) -> list[WorkOrder]` use case: Technician branch returns only assigned OTs for current shift; Supervisor branch returns all OTs for current shift in `backend/src/domain/use_cases/get_shift_work_orders.py`
- [X] T031 [US2] Implement `GET /api/v1/work-orders` router and `GET /api/v1/work-orders/{id}` router (both roles; Technician 403 if accessing unassigned OT); register in `backend/src/main.py` in `backend/src/adapters/inbound/routers/work_orders.py`

### Mobile — US2

- [X] T032 [P] [US2] Add `listForShift()` and `getById(id)` to `WorkOrderRepositoryImpl`: on success, write results to `CachedWorkOrderDao`; on connectivity failure, fall back to `CachedWorkOrderDao` and mark response as stale in `mobile/lib/data/remote/work_order_repository_impl.dart`
- [X] T033 [US2] Implement `TechnicianOtListNotifier` as `AsyncNotifier<OtListResult>` (where `OtListResult` carries `list + isStale` flag) with `loadList()` and pull-to-refresh in `mobile/lib/presentation/viewmodels/technician_ot_list_vm.dart`
- [X] T034 [P] [US2] Implement `WorkOrderDetailNotifier` as `AsyncNotifier<WorkOrder>` with `loadDetail(id)` in `mobile/lib/presentation/viewmodels/work_order_detail_vm.dart`
- [X] T035 [US2] Implement `OtListScreen`: shift OT cards (order type chip, technical location label, priority badge, planned dates, status badge Released/Notified), pull-to-refresh, staleness banner when data is from cache, empty state message in `mobile/lib/presentation/screens/technician/ot_list_screen.dart`
- [X] T036 [US2] Implement `OtDetailScreen`: all OT fields displayed without truncation (expandable text for long location names/descriptions), complete ordered step list; PMNN steps rendered as read-only informational cards; PM01 unregistered steps render an active "Register Closure" button; PM01 registered steps display closure summary; role check hides Register Closure button for Supervisor in `mobile/lib/presentation/screens/technician/ot_detail_screen.dart`
- [X] T037 [US2] Add `/technician/ots`, `/technician/ots/:id` routes to go_router (Technician only guard); add `technicianOtListProvider` and `workOrderDetailProvider` to `mobile/lib/core/di.dart`

**Checkpoint**: US2 complete — Technician sees assigned shift OTs; detail view shows all fields and step list with correct PMNN / PM01 indicators

---

## Phase 5: User Story 3 — Technician Registers PM01 Step Closure (Priority: P3)

**Goal**: Technician fills the 4-field closure form, submits, and either receives online
confirmation (OT → Notified if all PM01 steps done) or sees an offline queued indicator
that clears automatically when connectivity is restored.

**Independent Test**: See `quickstart.md` Story 3 section — register closure online,
verify OT → Notified; test offline submission and auto-sync on reconnect.

### Backend — US3

- [X] T038 [US3] Implement `register_step_closure` use case: validate target step is PM01 and has no existing closure (raise `StepAlreadyClosedError` for 409), INSERT `StepClosure` and check if all PM01 steps in the OT now have closures; if yes, atomically UPDATE `work_order.status='notified'`, `notif_final=true`, `sin_ttbjo_real=true` — all in a single DB transaction; return updated `WorkOrder` in `backend/src/domain/use_cases/register_step_closure.py`
- [X] T039 [US3] Implement `POST /api/v1/work-orders/{ot_id}/steps/{step_id}/closures` router (Technician only; assigned Technician only); map `StepAlreadyClosedError` → HTTP 409; return HTTP 201 with `WorkOrderDetail` in `backend/src/adapters/inbound/routers/work_orders.py`

### Mobile — US3

- [X] T040 [P] [US3] Implement `SyncService` as a Riverpod `AsyncNotifier` that: listens to `connectivity_plus` stream; on connectivity restoration, fetches all `pending` rows from `PendingClosureDao` ordered by `submitted_at`, POSTs each to the API, marks each `synced` or `failed` with error detail in `mobile/lib/data/remote/sync_service.dart`
- [X] T041 [US3] Add `registerClosure(otId, stepId, request)` to `WorkOrderRepositoryImpl`: check connectivity; if online, POST to API and return updated `WorkOrder`; if offline, INSERT into `pending_closures` via `PendingClosureDao` with `sync_status='pending'` and return an optimistic `WorkOrder` with the step marked locally in `mobile/lib/data/remote/work_order_repository_impl.dart`
- [X] T042 [US3] Implement `ClosureFormNotifier` as `Notifier<ClosureFormState>` with `updateActualDuration`, `updateDeviationKey`, `updateWorkDescription`, `updateSafetyResponse`, `submit(otId, stepId)` methods; on submit: validate all fields non-empty, call `WorkOrderRepository.registerClosure`; on success emit `ClosureSuccess(isQueued: bool)`; on validation failure emit `ClosureValidationError(fields)` in `mobile/lib/presentation/viewmodels/closure_form_vm.dart`
- [X] T043 [US3] Implement `ClosureFormScreen`: actual duration numeric field (decimal keyboard), deviation key dropdown, work description multiline field (no character limit, no line cap), safety question Yes/No toggle button pair; field-level validation highlights on submit attempt; loading indicator; success message distinguishing online ("Registrado") from offline ("En cola — se enviará al reconectar"); navigate back to OT detail on success in `mobile/lib/presentation/screens/technician/closure_form_screen.dart`
- [X] T044 [US3] Initialize `SyncService` provider eagerly on app start in `mobile/lib/core/di.dart`; add `/technician/ots/:ot_id/steps/:step_id/closure` route to go_router (Technician only); add `closureFormProvider` to `di.dart`

**Checkpoint**: US3 complete — online PM01 closure transitions OT to Notified; offline closures queue in SQLite and auto-sync on reconnect with no user action

---

## Phase 6: User Story 4 — Supervisor Monitors Shift Work Orders (Priority: P4)

**Goal**: Supervisor views all current-shift OTs with live Released/Notified status and
can open any Notified OT to read the full technician closure description (no truncation)
and the safety question response as an independent labelled field.

**Independent Test**: See `quickstart.md` Story 4 section — after Technician registers
closure (US3), Supervisor sees OT status as Notified and views full closure text.

**Backend note**: No new use cases or routers needed — `GET /api/v1/work-orders` already
returns all shift OTs for Supervisors (implemented in US2). `GET /api/v1/work-orders/{id}`
returns full closure detail including `work_description` and `safety_question_response`.

### Mobile — US4

- [X] T045 [P] [US4] Extend `SupervisorDashboardNotifier` (created in T027) to add `loadShiftList()` calling `WorkOrderRepository.listForShift()` with pull-to-refresh; replace the empty-list stub with real shift data in `mobile/lib/presentation/viewmodels/supervisor_dashboard_vm.dart`
- [X] T046 [US4] Implement `SupervisorDashboardScreen`: shift OT list with Released (orange)/Notified (green) status badges, pull-to-refresh, FAB navigating to `CreateWorkOrderScreen`, tap on OT navigates to OT detail in `mobile/lib/presentation/screens/supervisor/supervisor_dashboard_screen.dart`
- [X] T047 [US4] Update `OtDetailScreen` to display closure data for Supervisor role: for each registered PM01 step, show full `work_description` (no truncation — use scrollable `SelectableText`), and display `safety_question_response` as a separately labelled field ("¿Equipo con riesgo? Sí / No") distinct from the work description text in `mobile/lib/presentation/screens/technician/ot_detail_screen.dart`
- [X] T048 [US4] Add `/supervisor/ots`, `/supervisor/ots/:id` routes to go_router (Supervisor only guard); add `supervisorDashboardProvider` to `mobile/lib/core/di.dart`

**Checkpoint**: US4 complete — Supervisor views all shift OTs with live status; Notified OT detail shows full closure text and safety question response without truncation

---

## Phase 7: User Story 5 — Supervisor Views Technical Location Report (Priority: P5)

**Goal**: Supervisor opens the Technical Location Report and sees all locations ranked
descending by total registered OT count (including zeros).

**Independent Test**: See `quickstart.md` Story 5 section — after multiple OTs at
different locations, report is sorted correctly; count increments after new OT creation.

### Backend — US5

- [X] T049 [P] [US5] Implement `get_location_report` use case: LEFT JOIN `technical_locations` with `work_orders`, GROUP BY location, COUNT OT rows (includes zeros), sort DESC by count in `backend/src/domain/use_cases/get_location_report.py`
- [X] T050 [US5] Implement `GET /api/v1/technical-locations/report` router with `require_supervisor` dependency calling `get_location_report`; return `List[TechnicalLocationReportEntry]` in `backend/src/adapters/inbound/routers/technical_locations.py`

### Mobile — US5

- [X] T051 [P] [US5] Add `getLocationReport()` to `TechnicalLocationRepositoryImpl` calling `GET /api/v1/technical-locations/report` via Dio client in `mobile/lib/data/remote/technical_location_repository_impl.dart`
- [X] T052 [US5] Implement `LocationReportNotifier` as `AsyncNotifier<List<TechnicalLocationReportEntry>>` with `loadReport()` in `mobile/lib/presentation/viewmodels/location_report_vm.dart`
- [X] T053 [US5] Implement `LocationReportScreen`: ranked list of technical location cards showing full location path (sector / subsector / system / subsystem) and OT count badge in descending order, pull-to-refresh, accessible from Supervisor home or navigation drawer in `mobile/lib/presentation/screens/supervisor/location_report_screen.dart`
- [X] T054 [US5] Add `/supervisor/location-report` route to go_router (Supervisor only); add `locationReportProvider` to `mobile/lib/core/di.dart`; add "Location Report" entry to Supervisor navigation

**Checkpoint**: US5 complete — all 5 user stories demonstrable end-to-end

---

## Phase 8: User Story 6 — Supervisor Views Technician Workload (Priority: P6)

**Goal**: Supervisor opens a workload view showing all their technicians with OT count for
the current shift. Tapping a technician shows only their OTs. Technicians with 0 OTs appear.
Read-only — no create/modify actions visible.

**Independent Test**: See `quickstart.md` Story 6 section — verify workload list shows all
supervisor's technicians (including 0-count ones), drill-down shows only that technician's OTs,
Technician role gets 403 on the workload endpoint.

**Note**: No new DB tables or Drift local tables needed — US6 is a pure read-only aggregation
over existing `work_orders` and `users` data. The `?technician_id` filter reuses the existing
list endpoint.

### Backend — US6

- [X] T060 [US6] Add `get_workload_by_supervisor(supervisor_id, current_shift) -> List[TechnicianWorkload]` abstract method to `WorkOrderRepository` port in `backend/src/domain/ports/work_order_repository.py`; implement in `PostgresWorkOrderRepository` in `backend/src/adapters/outbound/postgres/repositories.py`: LEFT JOIN `work_orders` (shift_number = current_shift) onto `users` WHERE `users.created_by_id = supervisor_id AND users.role = 'technician'`, GROUP BY `users.id`, `users.display_name`, COUNT OT rows (0 for technicians with no OTs); return list ordered by `ot_count DESC, display_name ASC`
- [X] T061 [US6] Implement `get_technician_workload` use case: call `get_current_shift` to get active shift, call `work_order_repo.get_workload_by_supervisor(supervisor.id, shift)`, return `List[TechnicianWorkload]` in `backend/src/domain/use_cases/get_technician_workload.py`
- [X] T062 [US6] Add `GET /api/v1/work-orders/workload` endpoint in `backend/src/adapters/inbound/routers/work_orders.py` (Supervisor only via `require_supervisor` dependency) calling `get_technician_workload` use case; return `List[TechnicianWorkloadItem]`; **IMPORTANT**: register this route BEFORE the `/{id}` route to avoid FastAPI routing conflict
- [X] T063 [US6] Add optional `technician_id: UUID | None = Query(default=None)` parameter to `GET /api/v1/work-orders` in `backend/src/adapters/inbound/routers/work_orders.py`; when provided and role=Supervisor, pass it to `get_shift_work_orders` use case which filters results to OTs assigned to that specific technician; Technician role ignores the parameter

### Mobile — US6

- [X] T064 [P] [US6] Add `TechnicianWorkloadItemDto` Dart class with `fromJson` factory (fields: `technician_id`, `technician_name`, `ot_count`, `shift_number`) in `mobile/lib/data/remote/dtos/work_order_dto.dart`; add `TechnicianWorkload` domain model (fields: `technicianId`, `technicianName`, `otCount`, `shiftNumber`) in `mobile/lib/domain/models/work_order.dart`
- [X] T065 [US6] Add `getWorkload()` to abstract `WorkOrderRepository` interface in `mobile/lib/domain/repositories/work_order_repository.dart`; implement in `WorkOrderRepositoryImpl` in `mobile/lib/data/remote/work_order_repository_impl.dart`: call `GET /api/v1/work-orders/workload` via Dio, parse `List<TechnicianWorkloadItemDto>`, map to `List<TechnicianWorkload>`
- [X] T066 [US6] Implement `TechnicianWorkloadNotifier` as `AsyncNotifier<List<TechnicianWorkload>>` with `loadWorkload()` method in `mobile/lib/presentation/viewmodels/technician_workload_vm.dart`
- [X] T067 [US6] Create `TechnicianWorkloadScreen` in `mobile/lib/presentation/screens/supervisor/technician_workload_screen.dart`: list of technician cards showing `technicianName` and `otCount` badge (grey badge for 0, coloured for > 0); tap on card navigates to filtered OT list (reuse `OtListScreen` or inline list using `GET /api/v1/work-orders?technician_id={id}` via `WorkOrderRepositoryImpl.listForShift(technicianId: id)`); NO create/edit actions in this view; loading state; empty state ("No tienes técnicos registrados") if list is empty
- [X] T068 [US6] Add `/supervisor/workload` and `/supervisor/workload/:technician_id/ots` routes to go_router (Supervisor only) in `mobile/lib/core/router.dart`; add `technicianWorkloadProvider` to `mobile/lib/core/di.dart`; add "Carga de Trabajo" navigation entry in supervisor navigation (drawer or bottom nav)
- [ ] T069 [US6] Run Story 6 validation scenarios from `specs/002-ot-management/quickstart.md` end-to-end: workload endpoint returns all supervisor's technicians including 0-count ones, drill-down shows correct filtered OTs, Technician role receives 403 on workload endpoint

**Checkpoint**: US6 complete — all 6 user stories demonstrable end-to-end

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Hardening applicable across all stories

- [X] T055 [P] Add `StepAlreadyClosedError`, `NoPm01StepError`, `OtNotAssignedError` domain exceptions and map them to appropriate HTTP status codes in a global exception handler in `backend/src/main.py` (extend the existing error handler from feature 001)
- [X] T056 [P] Add pending-sync count badge to Technician home (e.g., icon with count) by reading `SyncService.pendingCount` from Riverpod; badge clears when all pending closures are synced in `mobile/lib/presentation/screens/technician/ot_list_screen.dart`
- [X] T057 [P] Add failed-sync recovery UI: for each `failed` pending closure in the queue, show an inline error card in `OtDetailScreen` with the server error message and a "Retry" button that calls `SyncService.syncPending()` in `mobile/lib/presentation/screens/technician/ot_detail_screen.dart`
- [X] T058 [P] Ensure go_router redirect guards enforce: Technicians cannot access `/supervisor/*` routes; Supervisors cannot access `/technician/*` routes in `mobile/lib/core/router.dart`
- [X] T059 Run all validation scenarios from `specs/002-ot-management/quickstart.md` end-to-end for all 5 stories including the offline Story 3 scenario

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately; T002, T003, T004 parallel
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
  - Backend: T005 → T007 ∥ T008; T006 → T008; T009 (needs T005 + T006) → T010 (needs T007 + T008 + T009)
  - Mobile: T011–T020 all independent (parallel); T013 → run `build_runner` after
- **US1 (Phase 3)**: Depends on Foundational — MVP gate
- **US2 (Phase 4)**: Depends on Foundational; practically needs US1 OTs to test
- **US3 (Phase 5)**: Depends on US2 (Technician must view OT detail before registering closure)
- **US4 (Phase 6)**: Depends on Foundational; backend already done in US2; mobile needs US1 screen pattern
- **US5 (Phase 7)**: Depends on Foundational; practically needs US1 OTs for non-zero report
- **US6 (Phase 8)**: Depends on Foundational + Feature 001 (technician-supervisor relationship via `created_by_id`); practically needs US1 OTs to show non-zero counts; builds on US2 backend list endpoint (`?technician_id` filter)
- **Polish (Final)**: Depends on all stories complete

### User Story Internal Ordering

For each story phase: backend use case → backend router → mobile repository impl → mobile notifier → mobile screen → routing + di wiring

### Parallel Opportunities

```
Phase 1:  T002 ∥ T003 ∥ T004

Phase 2 backend:
  T005 ∥ T006            (domain models independent)
  T007 ∥ T008            (ports independent)
  T009                   (needs T005, T006)
  T010                   (needs T007, T008, T009)

Phase 2 mobile:
  T011 ∥ T012 ∥ T013 ∥ T014 ∥ T015 ∥ T016 ∥ T017 ∥ T018 ∥ T019 ∥ T020

Phase 3 (US1):
  T021 ∥ T023 ∥ T024    (use case and utility routers parallel)
  T025 ∥ T026            (mobile repository implementations parallel)

Phase 4 (US2):
  T030 ∥ T034            (use case and detail notifier parallel)
  T032 ∥ T034            (repository impl and detail notifier parallel)

Phase 5 (US3):
  T040 ∥ T041 after T038/T039

Phase 6 (US4):
  T045 ∥ T047            (notifier and screen can be written in parallel)

Phase 7 (US5):
  T049 ∥ T051            (backend use case and mobile repo impl parallel)
  T052 ∥ (T049 backend) (notifier can be stubbed while backend is in progress)

Phase 8 (US6):
  T060 ∥ T064            (backend port+impl and mobile DTO parallel)
  T061                   (needs T060)
  T062 ∥ T063 ∥ T065    (router endpoints and mobile repo impl parallel after T060/T061)
  T066 ∥ T067            (notifier and screen can be written in parallel after T065)
```

---

## Implementation Strategy

### MVP First (US1 + US2 only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational ← **CRITICAL: blocks everything**
3. Complete Phase 3: US1 — Supervisor creates OT → **demo-able milestone**
4. Complete Phase 4: US2 — Technician views OTs → **demo-able milestone**
5. **STOP and VALIDATE**: Run Stories 1 and 2 from `quickstart.md`
6. Basic OT lifecycle visible to both roles → MVP achieved

### Incremental Delivery

1. Setup + Foundational → infrastructure ready
2. US1 → OT creation works end-to-end → **demo**
3. US2 → Technician view works with offline fallback → **demo**
4. US3 → Closure registration + offline sync → **demo** (core business action)
5. US4 → Supervisor monitoring → **demo** (shift oversight complete)
6. US5 → Location report → **demo** (analytics view)
7. US6 → Technician workload grouped view → **demo** (managerial visibility)
8. Polish → production-ready

### Key Implementation Notes

- The `get_current_shift` function (T003) must be tested standalone with edge cases:
  Shift 1 spans midnight (23:00–07:00); a naive time comparison will fail.
- The Drift `build_runner` in T013 generates `.g.dart` files — run after defining all
  table schemas and before any DAO implementations (T014, T015).
- The `SyncService` (T040) must be initialized eagerly at app start (T044) so that
  any pending closures from a previous app session are processed immediately when
  connectivity is available.
- The `activity_class` field is always set to `'plant machinery and equipment'` by the
  `create_work_order` use case — it never appears as a user-editable field in the UI.
