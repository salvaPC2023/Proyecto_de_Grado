# Feature Specification: LLM Description Standardization Module

**Feature Branch**: `003-llm-description-standardization`

**Created**: 2026-06-12

**Status**: Draft

**Input**: User description: "LLM-based OT description standardization module for a mobile maintenance app. This module extends the existing PM01 closure flow from feature 002-ot-management. After the technician writes their free-text description and before they submit the PM01 closure, the app sends the description to an external AI standardization service. The AI returns a structured, normalized version. The technician can review the standardized version, edit it if needed, and confirm it before submitting. The standardized description is what gets stored and shown to the supervisor."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Technician Standardizes PM01 Closure Description (Priority: P1)

A Technician writes a free-text description of the work performed in the PM01 step closure
form. Before submitting, they tap "Standardize description". The system sends the text to
an AI standardization service and displays a normalized, structured version. The Technician
reviews the result, edits it if needed, and confirms it as the final description. The
confirmed text is what gets stored in the closure record and shown to the Supervisor.

**Why this priority**: This is the core value of the module — converting inconsistent
free-text descriptions into structured, reviewable records that are easier for supervisors
to analyze. Without this story the module delivers no value.

**Independent Test**: Can be tested by opening a PM01 closure form (created in feature 002),
entering a free-text description such as "cambie el rodamiento del eje 2 y estaba desgastado",
tapping "Standardize description", reviewing the returned structured text, and submitting the
closure. The supervisor then opens the OT and confirms the closure description matches the
standardized (or edited) version.

**Acceptance Scenarios**:

1. **Given** a Technician on the PM01 closure form with a non-empty work description,
   **When** they tap "Standardize description", **Then** the app shows a loading indicator
   and, once the service responds, displays the standardized text in an editable field
   alongside "Confirm" and "Keep original" actions.
2. **Given** the standardized text is displayed, **When** the Technician taps "Confirm"
   without edits, **Then** the standardized text replaces the original in the work
   description field and the standardization panel closes.
3. **Given** the standardized text is displayed, **When** the Technician edits it and
   then taps "Confirm", **Then** the edited version is used as the work description.
4. **Given** the standardized text is displayed, **When** the Technician taps "Keep
   original", **Then** the original free-text is restored and the standardization panel
   closes without modifying the work description field.
5. **Given** a Technician who has already received a standardized version, **When** they
   modify the work description field and tap "Standardize description" again, **Then** a
   fresh standardization request is made for the updated text.
6. **Given** a Technician who confirmed a standardized description and then submits the
   closure, **When** the Supervisor opens the OT detail, **Then** the work description
   displayed is the text the Technician confirmed — not the original free-text.

---

### User Story 2 - Technician Submits Original Description When Standardization Is Unavailable (Priority: P2)

A Technician cannot or chooses not to use standardization — because the AI service is
unavailable, the request timed out, a quota limit was reached, the device is offline,
or the Technician simply prefers their own wording. The PM01 closure submission is never
blocked or delayed by any standardization outcome; the original description is always
accepted.

**Why this priority**: The closure registration flow from feature 002 must not be blocked
by a non-essential enhancement. Resilience of the submission path is critical to the app's
core mission.

**Independent Test**: Can be tested in two ways: (a) with the device offline, verify the
"Standardize description" button is hidden and the closure form is fully functional;
(b) with the AI service unreachable (simulated error), tap "Standardize description",
verify a clear error message appears, and confirm the Technician can still submit the
original description without extra steps.

**Acceptance Scenarios**:

1. **Given** a Technician who fills the closure form without tapping "Standardize
   description", **When** they submit the form, **Then** the original free-text
   description is stored as-is, with no standardization attempted.
2. **Given** a Technician who taps "Standardize description" and the AI service is
   unavailable or times out, **When** the failure occurs, **Then** the app shows a
   clear, non-blocking message (e.g., "Standardization unavailable. You can submit
   your original description.") and the work description field retains the original text.
3. **Given** an AI service error occurred, **When** the Technician taps "Retry",
   **Then** a new standardization request is sent; if it fails again, the error message
   is shown again and the original description remains intact.
4. **Given** a Technician whose device is offline, **When** they open the PM01 closure
   form, **Then** the "Standardize description" button is hidden or disabled with a
   clear indicator, and the rest of the closure form is fully functional.
5. **Given** a Technician in any fallback scenario, **When** they submit the closure
   with the original description, **Then** the submission proceeds exactly as it did
   before this module existed — no extra confirmation or warning is shown.

---

### Edge Cases

- What if the AI service returns a standardized description that is significantly shorter
  or longer than the original? The Technician reviews the full text before confirming;
  no length limit is enforced on either version.
- What if the standardized description appears nonsensical or technically incorrect? The
  Technician is responsible for reviewing accuracy. They can edit the text before
  confirming, or tap "Keep original" to discard it. The system does not auto-reject
  AI responses.
- What if the Technician closes the closure form after standardizing but before
  submitting? The standardized text (if confirmed into the field) is lost since the
  form is not persisted. On reopening, the Technician must re-enter and optionally
  re-standardize.
- What if the work description field is empty when the Technician taps "Standardize
  description"? The button is disabled until at least one character is entered in the
  work description field.
- What if the AI service is available but the device has very slow connectivity? The
  standardization request times out within a defined window; the timeout is treated
  as an unavailability error and the fallback flow applies.
- What happens when a Supervisor views a closure whose description was standardized?
  The Supervisor sees only the final description — no label, badge, or indicator
  distinguishes a standardized description from an original one. The Supervisor cannot
  modify the description after submission.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The PM01 closure form MUST include a "Standardize description" button that
  is visible and enabled only when the work description field contains at least one
  character AND the device is online.
- **FR-002**: When the Technician taps "Standardize description", the system MUST send
  the current work description to the AI standardization service and, on success, display
  the normalized text in an editable field alongside "Confirm" and "Keep original" actions.
- **FR-003**: The Technician MUST be able to edit the standardized text in the review
  field before confirming it.
- **FR-004**: When the Technician confirms, the closure form's work description field
  MUST be replaced with the confirmed text (standardized, or standardized-then-edited);
  the standardization panel MUST close.
- **FR-005**: When the Technician taps "Keep original", the original work description
  MUST be restored in the form and the standardization panel MUST close without
  persisting any changes.
- **FR-006**: If the AI standardization service returns an error or times out,
  the system MUST display a clear, non-blocking error message and MUST leave
  the original work description intact and submittable.
- **FR-007**: When the device is offline, the "Standardize description" button MUST be
  hidden or disabled; the closure form MUST remain fully functional without standardization.
- **FR-008**: PM01 closure submission MUST NOT be blocked, delayed, or conditioned on
  the use of standardization. A Technician who never taps the button MUST be able to
  submit with no additional steps.
- **FR-009**: The AI standardization service MUST produce output in Spanish, matching
  the language of the Technician's input.
- **FR-010**: Standardization MUST be triggered only by explicit Technician action;
  automatic or background standardization is not permitted.
- **FR-011**: The work description stored in the closure record MUST be exactly the text
  the Technician last confirmed — original, standardized, or standardized-then-edited.
  No secondary field tracks whether standardization was used.
- **FR-012**: The Supervisor's OT closure view (from feature 002) MUST display the
  final work description as-is, with no label or indicator distinguishing standardized
  from original descriptions. The Supervisor cannot modify the description after
  submission.
- **FR-013**: The standardization request sent to the AI service MUST include
  the Technician's work description, the OT type code (OE01–OE04), and the
  technical location label of the OT. No other fields are included. These
  values are read from the existing OT context already loaded in the PM01
  closure form and require no additional Technician input.
- **FR-014**: The app MUST apply a 10-second timeout to every standardization
  request. If no response is received within 10 seconds, the request is
  cancelled, the failure is treated identically to an AI service error
  (FR-006 applies), and the Technician is notified within 5 seconds of the
  timeout occurring (SC-004). The timeout value is fixed at the server
  component level and is not configurable by Supervisors or Technicians.
- **FR-015**: Standardization MUST NOT be attempted for closures submitted
  while the device is offline. Offline closures queued via local storage
  (feature 002) are synced to the server with the original free-text
  description as-is. No standardization is triggered at sync time. This
  is consistent with FR-007 (button hidden when offline) — if the Technician
  never had the option, no retroactive processing occurs.

### Key Entities

- **Standardization Request**: An ephemeral object sent to the AI standardization
  service. It is never persisted; its lifecycle ends when the Technician confirms
  or discards the result. It carries exactly three fields:
  - `work_description` (string): the free-text the Technician entered.
  - `order_type` (string): the OT type code (OE01–OE04), used to guide the AI
    in selecting relevant output sections (e.g. vibration measurements for
    predictive orders, corrective steps for OE01/OE03).
  - `technical_location` (string): the equipment label from the technical
    location tree, used to populate the "Equipo intervenido" section of the
    structured output.
- **Standardization Response**: The structured text returned by the AI service. Presented
  to the Technician for review and optional editing. Only the Technician-confirmed version
  enters the closure record.
- **Step Closure** (from feature 002, `work_description` field): Stores the final
  confirmed description — original, standardized, or edited. No schema change is needed;
  this module changes only what text the Technician enters before submitting.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The standardized description is returned and displayed to the Technician
  within 10 seconds of tapping the button under normal connectivity conditions.
- **SC-002**: 100% of PM01 closures remain submittable regardless of AI service
  availability — no closure submission is ever blocked or delayed by a standardization
  failure.
- **SC-003**: A Technician can complete the full standardization flow (enter
  description → tap button → review → confirm → submit) in under 3 minutes
  on first use. Note: given that some Technicians have limited technology
  familiarity (per organizational context), UI design must minimize
  interaction steps to support this criterion.
- **SC-004**: When the AI service is unavailable or the device is offline, the Technician
  is notified within 5 seconds and can proceed to submit the closure with the original
  description without any additional steps.
- **SC-005**: 0% of closure records are lost or corrupted due to AI service errors or
  timeouts — the original description is always available as the fallback value.

## Assumptions

- The AI standardization service is accessed through the app's server component; service
  credentials are managed server-side and are never embedded in the mobile application.
- The AI standardization service is accessed via the OpenAI API using the
  gpt-4o-mini model on a paid tier. Usage quota limitations are not an
  expected constraint; the fallback flow (FR-006, FR-014) handles transient
  network or service errors only.
- The standardization prompt is authored once by the development team and is not
  configurable by Supervisors or Technicians in this version.
- Input descriptions are in Spanish; the AI service is instructed to produce Spanish
  output. Multilingual support is out of scope.
- The original (pre-standardization) description is not retained in the database once
  the Technician confirms a standardized version. Only the final confirmed text is stored.
- The Technician is solely responsible for reviewing the standardized text for technical
  accuracy before confirming; the system does not evaluate or score the AI output quality.
- No character limit is imposed on the standardized description (consistent with feature
  002's unlimited free-text policy for work descriptions).
- The standardization service is stateless — each request is independent with no
  conversation history or learning from past closures.
- This module adds no maintenance recommendations, predictive failure analysis, or any
  AI capability beyond text standardization.
- The Supervisor's closure view (feature 002) requires no UI changes; the
  `work_description` field already displays whatever text the Technician submitted.
- Depends on feature 002 (OT Management): the PM01 closure form must exist and be fully
  functional before this module can be integrated.
- Network latency from Bolivia to AI provider infrastructure (primarily
  US/Europe-based) is an accepted variable. The 10-second timeout defined
  in FR-014 accounts for this. Provider selection should consider observed
  latency under representative connectivity conditions before going to
  production.