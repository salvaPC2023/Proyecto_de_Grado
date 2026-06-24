# Data Model: OT Management Module

**Feature**: `002-ot-management` | **Date**: 2026-06-08

---

## Backend — PostgreSQL

### Entity: `WorkOrder`

Central entity for this module. One row per Work Order (OT).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | UUID | PK, default gen_random_uuid() | |
| `order_type` | ENUM('OE01','OE02','OE03','OE04') | NOT NULL | |
| `technical_location_id` | UUID | FK → technical_locations.id, NOT NULL | |
| `assigned_technician_id` | UUID | FK → users.id, NOT NULL | |
| `created_by_id` | UUID | FK → users.id, NOT NULL | Supervisor who created the OT |
| `planner_group` | ENUM('mechanical','electrical','electronic') | NOT NULL | |
| `activity_class` | VARCHAR(100) | NOT NULL | Always 'plant machinery and equipment' (set by use case) |
| `installation_state` | ENUM('running','stopped') | NOT NULL | |
| `planned_start` | DATE | NOT NULL | ISO 8601 date |
| `planned_end` | DATE | NOT NULL | ISO 8601 date |
| `priority` | SMALLINT | NOT NULL, CHECK (1 ≤ priority ≤ 4) | 1=very high, 4=low |
| `status` | ENUM('released','notified') | NOT NULL, DEFAULT 'released' | Released on creation; Notified once all PM01 steps closed |
| `notif_final` | BOOLEAN | NOT NULL, DEFAULT false | Set true when OT transitions to Notified |
| `sin_ttbjo_real` | BOOLEAN | NOT NULL, DEFAULT false | Set true when OT transitions to Notified |
| `shift_number` | SMALLINT | NOT NULL, CHECK (1 ≤ shift_number ≤ 3) | Computed at creation from server timestamp; immutable after insert |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | |

**Indexes**:
- `INDEX (assigned_technician_id, shift_number, status)` — fast filter for Technician list view
- `INDEX (shift_number, status)` — fast filter for Supervisor shift view

**State Transitions**:
```
released ──[all PM01 steps closed]──► notified

Rules:
  • OT is created directly as Released (never stored as Open)
  • Released → Notified: triggered atomically by register_step_closure use case
    when all PM01 steps have valid StepClosures
  • notif_final and sin_ttbjo_real are set to true in the same transaction
  • There is no transition out of Notified
```

---

### Entity: `OTStep`

One row per step in an OT's ordered step list.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | UUID | PK, default gen_random_uuid() | |
| `work_order_id` | UUID | FK → work_orders.id ON DELETE CASCADE, NOT NULL | |
| `position` | SMALLINT | NOT NULL | 1-based display order |
| `description` | TEXT | NOT NULL | |
| `control_key` | ENUM('PMNN','PM01') | NOT NULL | |
| `planned_intervention_time` | DECIMAL(5,2) | NULLABLE | Required if control_key='PM01'; unit: hours |
| `is_fixed` | BOOLEAN | NOT NULL, DEFAULT false | true for the 3 pre-populated safety steps |

**Constraints**:
- `UNIQUE (work_order_id, position)` — positions must be unique per OT

**Invariants enforced by create_work_order use case**:
- Positions 1, 2, 3 are always the 3 fixed PMNN steps (injected by the use case)
- Custom steps start at position 4 and are appended in the order provided
- At least one PM01 step must exist (positions 4+) — use case rejects otherwise
- `planned_intervention_time` must be > 0 when `control_key = 'PM01'`

**Fixed step records injected at creation**:
| Position | Description | control_key | is_fixed |
|----------|-------------|-------------|----------|
| 1 | Piense de manera inteligente | PMNN | true |
| 2 | Vea, diga, haga algo | PMNN | true |
| 3 | Se tiene habilidades adecuadas para la tarea | PMNN | true |

---

### Entity: `StepClosure`

Registration record for a completed PM01 step. At most one per PM01 step.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | UUID | PK, default gen_random_uuid() | |
| `step_id` | UUID | FK → ot_steps.id, NOT NULL, UNIQUE | Enforces one closure per step |
| `actual_duration` | DECIMAL(5,2) | NOT NULL, CHECK (> 0) | Hours |
| `deviation_key` | ENUM('PM01 Executed','PM01 Not Executed') | NOT NULL | |
| `work_description` | TEXT | NOT NULL | Free-text, no character limit |
| `safety_question_response` | BOOLEAN | NOT NULL | true = Yes (risk exists), false = No |
| `submitted_at` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | Server timestamp |

**Constraint**: Only steps with `control_key = 'PM01'` may have a StepClosure.
Enforced by the `register_step_closure` use case (not a DB constraint, since the DB
would require a join check).

---

### Entity: `TechnicalLocation`

Read-only within this module. Pre-populated externally (seeded via Alembic or admin
import). Not modified by any OT management endpoint.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | UUID | PK, default gen_random_uuid() | |
| `sector` | VARCHAR(100) | NOT NULL | Hierarchy level 1 |
| `subsector` | VARCHAR(100) | NOT NULL | Hierarchy level 2 |
| `system` | VARCHAR(100) | NOT NULL | Hierarchy level 3 |
| `subsystem` | VARCHAR(100) | NOT NULL | Hierarchy level 4 (leaf node) |

**Constraints**:
- `UNIQUE (sector, subsector, system, subsystem)` — no duplicate leaf nodes
- `INDEX (sector, subsector, system)` — fast grouping for drill-down UI filtering

---

## Shift Constants (Domain Layer — Not Stored in DB)

Shifts are fixed 8-hour windows. The backend resolves the active shift from the server
timestamp using the `SERVER_TIMEZONE` environment variable (default `America/La_Paz`):

| Shift | Window |
|-------|--------|
| 1 | 23:00 – 07:00 (crosses midnight) |
| 2 | 07:00 – 15:00 |
| 3 | 15:00 – 23:00 |

These constants live in `backend/src/domain/models/shift.py` as a pure Python function
`get_current_shift(datetime) -> int` — no database table.

---

## Mobile — Flutter

### Local Drift Tables

#### `pending_closures`

Local queue for offline-submitted PM01 closures.

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | PK, auto-increment |
| `step_id` | TEXT | UUID string |
| `ot_id` | TEXT | UUID string (needed to build the API URL) |
| `actual_duration` | REAL | Hours |
| `deviation_key` | TEXT | 'PM01 Executed' or 'PM01 Not Executed' |
| `work_description` | TEXT | |
| `safety_question_response` | INTEGER | 0=false, 1=true |
| `submitted_at` | INTEGER | Unix timestamp milliseconds |
| `sync_status` | TEXT | 'pending' \| 'synced' \| 'failed' |
| `error_message` | TEXT NULLABLE | Server error detail if sync_status='failed' |

#### `cached_work_orders`

OT list cache for offline display.

| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT | UUID PK |
| `order_type` | TEXT | |
| `technical_location_id` | TEXT | UUID |
| `technical_location_label` | TEXT | Pre-formatted "sector / subsystem" label |
| `assigned_technician_id` | TEXT | UUID |
| `priority` | INTEGER | 1–4 |
| `planned_start` | TEXT | ISO 8601 date string |
| `planned_end` | TEXT | ISO 8601 date string |
| `status` | TEXT | 'released' \| 'notified' |
| `shift_number` | INTEGER | 1–3 |
| `cached_at` | INTEGER | Unix timestamp ms |

#### `cached_ot_steps`

OT step cache for offline detail view.

| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT | UUID PK |
| `work_order_id` | TEXT | UUID |
| `position` | INTEGER | 1-based |
| `description` | TEXT | |
| `control_key` | TEXT | 'PMNN' \| 'PM01' |
| `planned_intervention_time` | REAL NULLABLE | |
| `is_fixed` | INTEGER | 0 or 1 |
| `has_closure` | INTEGER | 0 or 1 (pre-computed flag from server response) |

---

### Pure Dart Domain Models

**`WorkOrder`**
```
id:                    String (UUID)
orderType:             String (OE01–OE04)
technicalLocation:     TechnicalLocation
assignedTechnicianId:  String (UUID)
priority:              int (1–4)
plannedStart:          DateTime
plannedEnd:            DateTime
status:                WorkOrderStatus (released | notified)
shiftNumber:           int (1–3)
```

**`OTStep`**
```
id:                       String (UUID)
workOrderId:              String (UUID)
position:                 int
description:              String
controlKey:               ControlKey (PMNN | PM01)
plannedInterventionTime:  double? (hours; non-null for PM01)
isFixed:                  bool
closure:                  StepClosure? (null for PMNN or unregistered PM01)
```

**`StepClosure`**
```
id:                      String (UUID)
actualDuration:          double (hours)
deviationKey:            DeviationKey (pm01Executed | pm01NotExecuted)
workDescription:         String
safetyQuestionResponse:  bool (true = Yes)
submittedAt:             DateTime
```

**`TechnicalLocation`**
```
id:        String (UUID)
sector:    String
subsector: String
system:    String
subsystem: String
```

**`TechnicianWorkload`** (US6 — read-only aggregation, never cached locally)
```
technicianId:    String (UUID)
technicianName:  String
otCount:         int (≥ 0)
shiftNumber:     int (1–3)
```

**`PendingClosure`** (mirrors Drift pending_closures row)
```
id:                      int
stepId:                  String
otId:                    String
actualDuration:          double
deviationKey:            String
workDescription:         String
safetyQuestionResponse:  bool
submittedAt:             DateTime
syncStatus:              SyncStatus (pending | synced | failed)
errorMessage:            String?
```

### ViewModel States

**`TechnicianOtListState`** (`AsyncNotifier<List<WorkOrder>>`)
| State | Meaning |
|-------|---------|
| `AsyncLoading` | Fetching from API |
| `AsyncData(list)` | Online list loaded |
| `AsyncData(cached)` | Offline — cached data with staleness flag |
| `AsyncError` | Network error with no cached data |

**`WorkOrderDetailState`** (`AsyncNotifier<WorkOrder>`)
| State | Meaning |
|-------|---------|
| `AsyncLoading` | Fetching detail |
| `AsyncData(ot)` | Detail loaded with full step list |
| `AsyncError` | Not found or network error |

**`ClosureFormState`** (`Notifier<ClosureFormData>`)
| State | Meaning |
|-------|---------|
| Initial | Empty form |
| Validated | All fields filled, ready to submit |
| Submitting | API call in progress or writing to local queue |
| Success | Submitted (online) or queued (offline) |
| Error | Validation failure or server rejection |

**`SupervisorDashboardState`** (`AsyncNotifier<List<WorkOrder>>`)
| State | Meaning |
|-------|---------|
| `AsyncLoading` | Fetching shift OT list |
| `AsyncData(list)` | Shift list loaded |
| `AsyncError` | Network error |

**`TechnicianWorkloadState`** (`AsyncNotifier<List<TechnicianWorkload>>`) — US6
| State | Meaning |
|-------|---------|
| `AsyncLoading` | Fetching workload summary |
| `AsyncData(list)` | All supervisor's technicians loaded with OT counts (includes otCount=0) |
| `AsyncError` | Network error |

---

## API ↔ Mobile Mapping

| Backend field | Mobile field | Notes |
|---------------|--------------|-------|
| `order_type` | `orderType` | String enum |
| `planned_start` | `plannedStart` | ISO 8601 date → DateTime |
| `planned_end` | `plannedEnd` | ISO 8601 date → DateTime |
| `assigned_technician_id` | `assignedTechnicianId` | UUID string |
| `shift_number` | `shiftNumber` | int |
| `is_fixed` | `isFixed` | bool |
| `planned_intervention_time` | `plannedInterventionTime` | double? hours |
| `control_key` | `controlKey` | enum |
| `safety_question_response` | `safetyQuestionResponse` | bool |
| `notif_final` | — | not shown in mobile UI; inferred from status |
| `sin_ttbjo_real` | — | not shown in mobile UI; inferred from status |
| `technician_id` | `technicianId` | US6 workload item: UUID of the technician |
| `technician_name` | `technicianName` | US6 workload item: display name |
| `ot_count` | `otCount` | US6 workload item: OT count for current shift |
