# Feature Specification: OT Management Module

**Feature Branch**: `002-ot-management`

**Created**: 2026-06-08

**Status**: Approved

**Input**: User description: "OT management module for a mobile maintenance app with two roles: Supervisor and Technician. Full lifecycle of Work Orders (OTs): creation by the supervisor, consultation by the technician, and closure registration by the technician."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Supervisor Creates Work Order (Priority: P1)

A Supervisor creates a new Work Order (OT) by selecting all required fields and defining
the ordered step list. The OT is assigned to a Technician and immediately becomes visible
in their shift queue.

**Why this priority**: Without OTs in the system, every other story has no data to act
on. OT creation is the foundational action that unlocks the entire module.

**Independent Test**: Create an OT with all required fields, define a step list with the
3 fixed safety steps plus at least one PM01 step, assign to a Technician, and verify the
OT appears in the Technician's view with all correct fields and steps.

**Acceptance Scenarios**:

1. **Given** a Supervisor on the Create OT screen, **When** they fill all required fields
   and define the step list, **Then** the OT is saved with status Released and assigned
   to the selected Technician.
2. **Given** a Supervisor opening the technical location selector, **When** they
   interact with it, **Then** they navigate the hierarchy (sector → subsector → system
   → subsystem) and can select any leaf node as the technical location.
3. **Given** a Supervisor creating an OT, **When** the step list is initialised, **Then**
   the first 3 steps are automatically pre-populated as fixed read-only PMNN safety
   steps in this exact order:
   1. 'Piense de manera inteligente'
   2. 'Vea, diga, haga algo'
   3. 'Se tiene habilidades adecuadas para la tarea'
4. **Given** a Supervisor adding a custom step after the 3 fixed steps, **When** they
   choose control key PM01, **Then** the form also requires a planned intervention time
   for that step.
5. **Given** a Supervisor submitting an OT with no PM01 step in the step list,
   **When** they try to save, **Then** a validation error requires at least one PM01 step
   before the OT can be created.
6. **Given** a Supervisor submitting the Create OT form with any required field missing,
   **When** they try to save, **Then** a field-level validation error is shown and the
   OT is not created.

---

### User Story 2 - Technician Views Assigned Work Orders (Priority: P2)

A Technician views the list of OTs assigned to them for the current shift, and opens any
OT to see its full detail including the complete ordered step list.

**Why this priority**: Technicians must see their work queue before they can register
any closure. This story is the prerequisite to Story 3.

**Independent Test**: Assign an OT to a Technician (via Story 1), log in as that
Technician, verify the OT appears in the list with correct summary data, open it, and
verify every field and step is displayed correctly and in full.

**Acceptance Scenarios**:

1. **Given** a Technician on their home screen, **When** they view the OT list, **Then**
   only OTs assigned to them for the current shift are displayed.
2. **Given** a Technician viewing the OT list, **When** the list renders, **Then** each
   OT card shows: order type, technical location, priority, planned start/end dates, and
   current status (Released / Notified).
3. **Given** a Technician opening an OT, **When** the detail view loads, **Then** all
   OT fields are shown: order type, planned intervention time, priority, technical
   location, installation state, and the complete ordered step list with control key
   indicators for each step.
4. **Given** a Technician viewing the step list, **When** the list renders, **Then**
   PMNN steps are clearly marked as read-only informational steps and PM01 steps are
   clearly actionable (the Technician can open the closure form for them).
5. **Given** any text field (description, technical location name) in the OT detail
   view, **When** the text is long, **Then** the full content is visible without
   truncation.

---

### User Story 3 - Technician Registers PM01 Step Closure (Priority: P3)

A Technician opens a PM01 step closure form, fills in all required fields (actual
duration, deviation key, work description, safety question response), and submits. When
all PM01 steps in the OT are registered, the system confirms the OT as Notified. Offline
submissions are stored locally and synced automatically.

**Why this priority**: This is the module's primary business action — every other story
exists to support or result from this core registration.

**Independent Test**: Open an OT with exactly one PM01 step as a Technician, fill all
closure fields, submit, and verify: the step is marked registered, the OT status changes
to Notified, and the Supervisor can see the full closure description.

**Acceptance Scenarios**:

1. **Given** a Technician opening a PM01 step, **When** the closure form loads, **Then**
   it shows four fields: actual duration (hours), deviation key selector
   ('PM01 Executed' / 'PM01 Not Executed'), free-text work description (no character
   limit), and safety question ('Does the equipment carry a risk after this
   maintenance?' — Yes / No).
2. **Given** a Technician submitting a PM01 closure with all fields filled,
   **When** the submission succeeds, **Then** the step is marked as registered and the
   OT status updates to reflect the current state.
3. **Given** all PM01 steps in an OT are registered with valid data, **When** the last
   PM01 step is submitted, **Then** the system automatically sets the 'Notif. final' and
   'Sin ttbjo. real' flags and the OT transitions to Notified status.
4. **Given** a Technician attempting to submit a PM01 closure with any required field
   empty, **When** they tap submit, **Then** each missing field is highlighted with a
   validation message and the data is not sent; the OT transitions to Released status.
5. **Given** a Technician who is offline when they submit a PM01 closure with all fields
   filled, **When** they submit, **Then** the data is stored locally, a visual indicator
   shows 'pending sync', and the closure is transmitted automatically once connectivity
   is restored.
6. **Given** one or more closures are pending sync, **When** the device reconnects to
   the network, **Then** all queued closures are sent automatically without any user
   action, and the visual indicator clears on success.
7. **Given** a Technician typing in the work description field, **When** they enter a
   long text, **Then** there is no character limit enforced and the full text is
   accepted and displayed.

---

### User Story 4 - Supervisor Monitors Shift Work Orders (Priority: P4)

A Supervisor views all OTs for the current shift with their live status, and can inspect
the full closure details — including the technician's work description and the safety
question response — for any Notified OT.

**Why this priority**: Supervisors need live visibility over shift progress to manage
workload and validate the quality of completed work.

**Independent Test**: After a Technician closes an OT (Story 3), log in as Supervisor,
verify the OT appears in the shift list with status Notified, open it, and verify the
full technician-entered description and safety question response are visible without
truncation.

**Acceptance Scenarios**:

1. **Given** a Supervisor on their home screen, **When** they view the shift OT list,
   **Then** all OTs for the current shift are shown with their current status
   (Released / Notified).
2. **Given** a Supervisor opening a Notified OT's detail view, **When** the view loads,
   **Then** the full work description submitted by the Technician is displayed without
   any truncation.
3. **Given** a Supervisor viewing a Notified OT, **When** the safety question field is
   shown, **Then** the Technician's Yes/No response is displayed as an independent,
   clearly labelled field.
4. **Given** a Supervisor viewing the shift OT list, **When** an OT status changes
   (e.g., Released → Notified), **Then** the list reflects the new status within one
   manual refresh or automatically.

---

### User Story 5 - Supervisor Views Technical Location Report (Priority: P5)

A Supervisor views a ranked list of all technical locations sorted by the number of
registered OTs, providing data-driven visibility into which equipment areas have the
highest maintenance activity.

**Why this priority**: This report adds planning value once OTs are being created and
closed (Stories 1–4 complete). It has no blocking dependencies on other stories.

**Independent Test**: After creating OTs for at least two different technical locations,
open the technical location report as a Supervisor and verify the list is sorted in
descending order by OT count.

**Acceptance Scenarios**:

1. **Given** a Supervisor opening the technical location report, **When** the report
   loads, **Then** all technical locations are listed with their registered OT count,
   sorted in descending order by count.
2. **Given** a technical location with zero registered OTs, **When** the report loads,
   **Then** it appears with a count of 0.
3. **Given** a Supervisor viewing the report after a new OT is closed at a location,
   **When** they refresh the report, **Then** the updated count is reflected.

---

### User Story 6 - Supervisor Views Technician Workload (Priority: P6)

A Supervisor opens a workload view that lists all of their technicians, showing at a glance
how many OTs each one has assigned in the current shift. Tapping a technician reveals the
specific OTs assigned to them. This view is read-only.

**Why this priority**: This view adds managerial visibility once OTs are being created
(Stories 1–4 complete). It complements the flat shift OT list (US4) by grouping OTs
per technician, helping the Supervisor spot imbalances or bottlenecks in workload
distribution at a glance.

**Independent Test**: Create OTs assigned to two different technicians under the same
Supervisor, open the workload view, verify both technicians appear with their correct OT
counts, tap one technician, and verify only their OTs are shown.

**Acceptance Scenarios**:

1. **Given** a Supervisor opening the workload view, **When** the list loads, **Then**
   all technicians belonging to that Supervisor are listed, each showing their name and
   the number of OTs assigned to them in the current shift.
2. **Given** a technician with no OTs in the current shift, **When** the workload list
   loads, **Then** that technician still appears in the list with a count of 0.
3. **Given** a Supervisor tapping a technician in the workload list, **When** the detail
   loads, **Then** only the OTs assigned to that specific technician in the current shift
   are displayed with their order type, technical location, and status.
4. **Given** a Supervisor viewing the technician OT detail from the workload view,
   **When** they interact with it, **Then** no creation or modification actions are
   available — the view is strictly read-only.
5. **Given** a Supervisor whose technicians have no OTs at all, **When** the workload
   view loads, **Then** all technicians are listed with count 0 and no error is shown.

---

### Edge Cases

- A Technician submits the final PM01 step while offline: the 'Notif. final' and
  'Sin ttbjo. real' flags cannot be confirmed until sync; the OT stays in Released status
  until the pending closure is transmitted and the system processes it.
- A Technician who is offline attempts to view their OT list: previously cached OT data
  is shown; OTs assigned after the last sync are not visible until connectivity is
  restored.
- A very long work description is submitted and then viewed by a Supervisor: the full
  text must be readable without truncation in the Supervisor's detail view.
- The OT has multiple PM01 steps and the Technician completes them in any order: the
  OT transitions to Notified only when all PM01 steps have valid closure records.
- All of the Supervisor's technicians have zero OTs in the current shift: the workload
  list renders normally with all technicians shown at count 0, no empty-state error.

## Requirements *(mandatory)*

### Functional Requirements

**OT Creation (Supervisor)**

- **FR-001**: Supervisors MUST be able to create a Work Order (OT) with the following
  mandatory fields: order type (OE01 / OE02 / OE03 / OE04), technical location
  (selected from the hierarchical equipment tree), assigned technician, planner group
  (mechanical / electrical / electronic), activity class, installation state
  (running / stopped), planned start date, planned end date, and priority
  (1 = very high / 2 = high / 3 = medium / 4 = low).
- **FR-002**: The system MUST automatically pre-populate the first 3 steps of every OT
  as fixed PMNN safety steps in this order:
  (1) 'Piense de manera inteligente',
  (2) 'Vea, diga, haga algo',
  (3) 'Se tiene habilidades adecuadas para la tarea'.
  These steps MUST NOT be editable or removable.
- **FR-003**: Supervisors MUST be able to append custom steps after the 3 fixed steps.
  Each custom step requires a description and a control key (PMNN or PM01).
  PM01 steps additionally require a planned intervention time.
- **FR-004**: The system MUST reject OT creation if the step list contains no PM01 step,
  surfacing a clear error message.
- **FR-005**: The system MUST validate all required OT fields before saving and MUST
  surface a specific error for each missing or invalid field.
- **FR-006**: Supervisors MUST be able to navigate the technical location hierarchy
  (sector → subsector → system → subsystem) via a drill-down selector.

**Technician OT View**

- **FR-007**: Technicians MUST see only OTs assigned to them for the current shift.
- **FR-008**: The OT list MUST display for each OT: order type, technical location,
  priority, planned start and end dates, and current status.
- **FR-009**: Technicians MUST be able to open an OT and view all its fields and its
  complete ordered step list with the control key (PMNN / PM01) indicated per step.
- **FR-010**: PMNN steps MUST be read-only in the Technician view. PM01 steps MUST be
  actionable — the Technician can open the closure form from them.
- **FR-011**: No text in the OT detail view MUST be truncated; all descriptions and
  location names MUST be fully visible.

**PM01 Step Closure (Technician)**

- **FR-012**: Technicians MUST be able to open a closure form for any unregistered PM01
  step containing: actual duration (hours), deviation key
  ('PM01 Executed' / 'PM01 Not Executed'), free-text work description (no character
  limit), and safety question ('Does the equipment carry a risk after this maintenance?'
  — Yes / No).
- **FR-013**: The system MUST validate that all four closure form fields are filled
  before submission. Missing fields MUST be highlighted; the submission MUST be blocked.
- **FR-014**: On successful submission of all PM01 steps, the system MUST automatically
  set the 'Notif. final' and 'Sin ttbjo. real' flags and transition the OT to Notified.
- **FR-015**: If a PM01 closure submission is blocked by validation, the OT MUST
  remain in Released status and the step MUST remain actionable.
- **FR-016**: The safety question response (Yes / No) MUST be stored as an independent
  field, separate from the work description.
- **FR-017**: When offline, PM01 closure data MUST be stored locally with a visible
  'pending sync' indicator. Data MUST be transmitted automatically when connectivity
  is restored, with no user action required.
- **FR-022**: When an offline closure fails to sync after reconnection, the system
  MUST display an inline error indicator on the affected OT with a Retry action.
  The Technician MUST be able to manually trigger a retry without re-entering
  closure data.

**Supervisor Monitoring**

- **FR-018**: Supervisors MUST see all OTs for the current shift with their status
  (Released / Notified).
- **FR-019**: For any Notified OT, Supervisors MUST be able to view the full work
  description entered by the Technician, with no truncation.
- **FR-020**: The Technician's safety question response MUST be displayed as an
  independent, clearly labelled field in the Supervisor's OT detail view.

**Technical Location Report**

- **FR-021**: Supervisors MUST be able to view a list of all technical locations sorted
  by registered OT count in descending order.

**Technician Workload View**

- **FR-023**: Supervisors MUST be able to view a list of all their own technicians, each
  showing the number of OTs assigned to them in the current shift.
- **FR-024**: Technicians with zero OTs in the current shift MUST appear in the list with
  a count of 0.
- **FR-025**: Supervisors MUST be able to tap a technician in the workload list to see the
  OTs assigned to that technician for the current shift, displaying order type, technical
  location, and current status for each OT.
- **FR-026**: The technician workload view and its OT drill-down MUST be read-only — no
  OT creation or modification actions are available.

### Key Entities

- **Work Order (OT)**: Central entity. Attributes: order type (OE01–OE04), technical
  location, assigned technician, planner group, activity class, installation state
  (running / stopped), planned start date, planned end date, priority (1–4), status
  (Released | Notified), flags: Notif. final (boolean), Sin ttbjo. real (boolean),
  assigned shift (Shift 1 | Shift 2 | Shift 3).
- **OT Step**: An ordered item in an OT's step list. Attributes: position (integer),
  description, control key (PMNN | PM01), planned intervention time (PM01 only),
  is-fixed (boolean, true for the first 3 steps).
- **Step Closure**: Registration record for a PM01 step. Attributes: actual duration
  (hours, decimal), deviation key (PM01 Executed | PM01 Not Executed), work description
  (free-text, unlimited), safety question response (Yes | No), sync status
  (synced | pending-sync), submitted at (timestamp).
- **Technical Location**: Equipment hierarchy node (sector → subsector → system →
  subsystem). Read-only within this module; pre-populated externally.
- **Shift**: A fixed 8-hour time window. Three shifts are predefined system-wide:
  Shift 1 (23:00–07:00), Shift 2 (07:00–15:00), Shift 3 (15:00–23:00). The active
  shift is determined by the current timestamp. OTs are associated with the shift active
  at the time of creation and filtered accordingly in all list views.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A Supervisor can create a complete OT with a full step list in under
  5 minutes on the first use.
- **SC-002**: A Technician's shift OT list loads within 3 seconds under normal
  connectivity. *(post-launch KPI — no buildable verification task required for thesis scope)*
- **SC-003**: A PM01 closure submission (online) is confirmed to the Technician within
  5 seconds. *(post-launch KPI — no buildable verification task required for thesis scope)*
- **SC-004**: 100% of online PM01 closures result in the correct OT status transition
  within one server round-trip.
- **SC-005**: Offline closures sync automatically within 30 seconds of connectivity
  restoration with zero data loss. *(post-launch KPI — no buildable verification task required for thesis scope)*
- **SC-006**: No text field in any view truncates content — the full text of every
  description, technical location name, or work record is always readable.
- **SC-007**: The technician workload list loads within 3 seconds and displays accurate
  OT counts for all of the Supervisor's technicians.

## Assumptions

- The technical location hierarchy is pre-loaded and is read-only within this module;
  creating or modifying technical locations is out of scope.
- The equipment hierarchy tree uses a drill-down navigation UI; keyword search within
  the tree is not required in this version.
- Supervisors cannot edit or reassign an OT after creation; post-creation modifications
  are out of scope.
- Activity class has a single applicable value ('plant machinery and equipment') for this
  project; a selector with one pre-selected option is acceptable.
- OT deletion is out of scope; all created OTs persist in the system.
- Push notifications for OT assignment are out of scope for this feature and will be
  handled by a dedicated notifications module.
- The ICM performance indicator calculation is out of scope; this module only ensures the
  correct flags and statuses are set so external tools can calculate ICM accurately.
- Shifts are fixed and predefined system-wide — three 8-hour windows:
  Shift 1 (23:00–07:00), Shift 2 (07:00–15:00), Shift 3 (15:00–23:00). The system
  determines the active shift from the current timestamp; no shift management screen is
  required. OTs are associated with the shift active at the time of creation, and the
  OT lists for both Technicians and Supervisors are filtered by that shift association.
- An OT transitions to Released status automatically upon creation — Released is the
  first and only persistent status a saved OT can hold before closure. The Open status
  is a transient UI state that exists only while the Supervisor is filling the creation
  form; it is never persisted or displayed in any list view. The only meaningful
  lifecycle transition tracked by the app is Released → Notified, which requires a
  correct closure with all mandatory fields and automatic confirmation of 'Notif. final'
  and 'Sin ttbjo. real' flags. This mirrors SAP IW31 behaviour.
