# Research: OT Management Module

**Feature**: `002-ot-management` | **Date**: 2026-06-08

All decisions below resolve unknowns that would otherwise block design or implementation.
Each decision cites the spec assumption it fulfills and the Constitution principle it
respects.

---

## Decision 1: Shift Computation

**Decision**: Shift number is computed **server-side** from the server's clock at the
instant the OT is created or a list is requested. The backend resolves the active shift
using three hardcoded time windows (constants in the domain layer, not DB rows):

| Shift | Start | End |
|-------|-------|-----|
| 1     | 23:00 | 07:00 |
| 2     | 07:00 | 15:00 |
| 3     | 15:00 | 23:00 |

The server timezone is configured via `SERVER_TIMEZONE` env var (default:
`America/La_Paz`, UTC-4). Bolivia does not observe DST, so no DST-related edge cases
apply. The `GET /api/v1/shifts/current` endpoint returns the current shift number
and the server datetime so the mobile can display shift context without computing it
independently.

**Rationale**: Centralising shift computation on the server eliminates clock skew and
timezone discrepancies between mobile devices. The 3 fixed windows are hardcoded domain
constants — no DB table, no management screen — satisfying Principle V (Simplicity).

**Alternatives considered**:
- *Client-side computation* — rejected: mobile device clocks may drift; timezone
  configuration on individual devices is outside the system's control.
- *Shift table in DB* — rejected: unnecessary abstraction; shifts are immutable
  system-wide constants.

---

## Decision 2: Technical Location Storage

**Decision**: The `technical_locations` table stores each leaf node as a **flat row** with
four fixed-depth columns: `sector`, `subsector`, `system`, `subsystem`. The mobile
implements the drill-down UI by grouping and filtering the full list returned by
`GET /api/v1/technical-locations`.

**Rationale**: The hierarchy depth is fixed at 4 levels and will not change. A flat
table allows a single SQL query to retrieve all locations without recursive CTEs or
adjacency-list joins. The full list for a typical industrial plant is small (hundreds of
nodes, not millions), so returning it all at once is acceptable and simpler than a
level-by-level API.

**Alternatives considered**:
- *Adjacency list (parent_id)* — rejected: adds JOIN complexity and a recursive query
  for arbitrary depth, with no benefit since depth is fixed.
- *Materialised closure table* — rejected: severe over-engineering for a fixed 4-level
  tree.
- *Level-by-level API (`?level=subsector&sector=X`)* — rejected: requires 4 API calls
  to fully navigate; full-list approach uses one call and is simpler (Principle V).

---

## Decision 3: Fixed PMNN Safety Steps

**Decision**: The 3 mandatory safety steps are **stored in the `ot_steps` table**
alongside custom steps, with `is_fixed = true`. The `create_work_order` use case
injects them at positions 1, 2, and 3 before appending any custom steps provided by
the Supervisor. Their descriptions are hardcoded domain constants:

1. `'Piense de manera inteligente'`
2. `'Vea, diga, haga algo'`
3. `'Se tiene habilidades adecuadas para la tarea'`

The API contract for OT creation only accepts custom steps (the 3 fixed steps are never
in the request body). Downstream queries always retrieve the full step list from the
table in `position` order.

**Rationale**: Storing them in the same table keeps the step list complete and
ordered in one relation. Enforcing immutability at the use-case layer (not the DB) is
simpler and sufficient. Principle V: no need for a separate `fixed_steps` table or
a special-purpose query.

**Alternatives considered**:
- *Hardcoded in domain, merged at read time* — rejected: complicates every OT detail
  query; position ordering becomes fragile.
- *Separate `fixed_steps` table* — rejected: premature abstraction; the same domain
  object model handles both step types.

---

## Decision 4: Offline Closure Queue

**Decision**: PM01 closures submitted while offline are persisted in a Drift/SQLite
table `pending_closures`. A `SyncService` (a Riverpod `AsyncNotifier` provider) listens
to the `connectivity_plus` stream. When connectivity transitions from disconnected to
connected, it processes all `pending` records in ascending `submitted_at` order,
sending each to `POST /api/v1/work-orders/{ot_id}/steps/{step_id}/closures`.

**Sync outcome states**:
- `pending` — awaiting connectivity
- `synced` — successfully transmitted (record can be deleted)
- `failed` — server rejected (HTTP 4xx); surface error to user with detail

**Conflict prevention**: The `step_closures` table has a `UNIQUE` constraint on
`step_id`. If a pending closure reaches the server for a step that was already closed
(e.g., by a second device or a double-tap), the server returns HTTP 409. The mobile
marks the record `failed` and informs the user.

**Rationale**: Drift is already a project dependency (constitution Technology Stack).
Persisting to SQLite ensures the queue survives app restarts and process kills. Auto-sync
on reconnection with no user action satisfies FR-017 and SC-005.

**Alternatives considered**:
- *In-memory queue* — rejected: lost on app close/crash; violates SC-005 (zero data
  loss).
- *WorkManager / background service* — rejected: platform-specific complexity; Riverpod
  lifecycle with connectivity_plus is sufficient for the project's scope.

---

## Decision 5: OT List Caching for Offline Display

**Decision**: After each successful `GET /api/v1/work-orders` (Technician) or
`GET /api/v1/work-orders/{id}` (detail), the mobile overwrites the relevant rows in
Drift tables `cached_work_orders` and `cached_ot_steps`. When offline, the
`WorkOrderRepository` falls back to these Drift tables and appends a staleness
banner to the UI.

**Cache invalidation**: Full overwrite on every successful fetch; no TTL. Stale data
is acceptable (spec edge case: "previously cached OT data is shown").

**Rationale**: The spec explicitly states that offline Technicians should see previously
cached OTs. Drift is already in use for the closure queue, so adding DAOs for OT
caching adds minimal complexity.

**Alternatives considered**:
- *No caching* — rejected: directly contradicts the offline edge case in spec.md.
- *HTTP cache headers + offline-first strategy* — rejected: Dio does not implement
  offline-first caching out of the box; Drift is already the project's local store.

---

## Decision 6: OT Status Transition Trigger

**Decision**: The `register_step_closure` use case, after persisting a new
`StepClosure`, queries the OT's PM01 step count and compares it with the count of
valid closures. If they match (all PM01 steps have closures), it atomically:

1. Sets `work_order.notif_final = true`
2. Sets `work_order.sin_ttbjo_real = true`
3. Sets `work_order.status = 'notified'`

All three updates and the closure INSERT are committed in a single DB transaction.

**Rationale**: Domain rule computed in the use case layer — no external event bus, no
database trigger, no scheduled job. This is the simplest correct implementation
(Principle V) and keeps the logic visible in the domain layer (Principle III).

**Alternatives considered**:
- *PostgreSQL trigger* — rejected: puts business logic in the DB, outside the hexagonal
  domain layer.
- *Scheduled polling job* — rejected: unnecessary complexity; the transition is
  deterministic and can be evaluated at closure time.

---

## Decision 7: Work Order List Endpoint — Role Filtering

**Decision**: A single endpoint `GET /api/v1/work-orders` with role-based filtering
in the use case layer:
- **Technician**: returns OTs assigned to them for the current server shift.
- **Supervisor**: returns all OTs for the current server shift.

No `?shift_number` query parameter for historical shifts — per spec, only the current
shift is displayed (Principle V).

**Rationale**: Both roles use the same response schema (`WorkOrderSummary`). Role-based
filtering at the use-case layer keeps the router thin and the domain logic explicit.

**Alternatives considered**:
- *Separate endpoints per role (`/my-work-orders`, `/shift-work-orders`)* — rejected:
  doubles the API surface with no data-shape difference.
- *Historical shift filter* — rejected: not in spec; YAGNI.

---

## Decision 8: activity_class Field

**Decision**: `activity_class` is stored as `VARCHAR(100) NOT NULL` with a hardcoded
default `'plant machinery and equipment'` applied in the `create_work_order` use case.
It is **not** a user-selectable field. The mobile UI shows it as a pre-filled, read-only
label.

**Rationale**: Per spec assumption, a single applicable value exists for this project.
Hardcoding it in the use case (not the API schema) allows a future spec to expose it as
a selector without a breaking API change.

**Alternatives considered**:
- *Remove from API entirely* — rejected: the field must appear in OT detail view (it is
  a real SAP field and must be displayed to match IW32 context).
- *ENUM in DB* — rejected: a single-value ENUM brings no benefit over VARCHAR with a
  use-case-level default.
