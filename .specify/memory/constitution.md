<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.2 → 1.1.0 (MINOR — Principle III mobile architecture materially expanded)

--- History ---

v1.0.0 (2026-06-08): Initial fill from blank template
  Added sections: Core Principles (I–V), Technology Stack, Development Workflow, Governance
  Principle III was "Clean Architecture" (replaced in v1.0.1)

v1.0.1 (2026-06-08): Project-specific amendments
  Modified principles:
    - Principle III: "Clean Architecture" → "Hexagonal Architecture (Ports & Adapters)"
      (added diagram; added MVVM rule for Flutter client)
  Technology Stack expanded:
    - Mobile fixed to Flutter (Dart) — React Native removed
    - Added: Railway (deploy), Firebase FCM (push notifications),
              Firebase Storage (image store), LLM API adapter
  Constraints added:
    - Loading states required for all async calls
    - Offline OT registration with automatic sync

v1.0.2 (2026-06-08): Sync Impact Report corrected; no semantic changes

v1.1.0 (2026-06-08): Principle III mobile architecture expanded
  - MVVM + Riverpod: ViewModel (Riverpod Notifiers) owns state; Repository
    is the sole data-access port.
  - Local SQLite via Drift added as the offline persistence layer.
  - BLoC/Cubit explicitly forbidden.
  - Technology Stack → Mobile entry updated (Riverpod + Drift).

--- Template Status ---
  .specify/templates/plan-template.md ✅ (Constitution Check gate present; generic fill at plan time)
  .specify/templates/spec-template.md ✅ (technology-agnostic; no changes needed)
  .specify/templates/tasks-template.md ✅ (path conventions match Mobile + API stack)

--- Deferred TODOs ---
  None. RATIFICATION_DATE resolved to 2026-06-08 (first authoring date).
-->

# Proyecto de Grado Constitution

## Core Principles

### I. API-First

The REST/HTTP API contract MUST be defined and agreed upon before any backend
implementation or mobile client code is written. Contracts live in
`specs/[feature]/contracts/` as OpenAPI or equivalent schema documents.

- Backend MUST implement against the published contract; deviations require a
  contract amendment and a new review.
- Mobile clients MUST consume only documented endpoints; undocumented coupling
  is forbidden.
- Breaking contract changes (field removal, type change, endpoint removal) MUST
  increment the API major version and be flagged in the feature spec.

**Rationale**: Enforces a clean boundary between the Python backend and the
Flutter client, enabling parallel development and preventing silent contract
drift that causes integration failures late in the project.

### II. Documentation-Driven

Every feature MUST pass through the Spec Kit pipeline in order:
`/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`.
No implementation task may begin without an approved `spec.md` and `plan.md`.

- The feature spec is the single source of truth for requirements. Code that
  has no corresponding spec entry is considered out-of-scope.
- Documentation artifacts (spec, plan, contracts, quickstart) MUST be committed
  alongside the code changes they describe, in the same branch.
- Acceptance scenarios in `spec.md` MUST be manually verified before a feature
  is considered complete.

**Rationale**: As a thesis project evaluated by an academic committee, every
design decision and requirement must be traceable. Documentation-first ensures
that the written deliverables remain consistent with the working software.

### III. Hexagonal Architecture (Ports & Adapters)

The backend (FastAPI) MUST be structured around a domain core that is fully
isolated from external concerns. All communication with the outside world
(HTTP, database, LLM APIs, Firebase) MUST pass through explicitly defined
ports (interfaces) and adapters (implementations).

```
Inbound adapters (FastAPI routers)
        ↓
   [ Application / Use Cases ]
        ↓
   [ Domain Core — pure business logic ]
        ↑
   [ Ports — interfaces ]
        ↑
Outbound adapters (PostgreSQL, LLM API, FCM/Firebase)
```

- No domain or use-case code may import directly from FastAPI, SQLAlchemy,
  or any third-party library. Dependencies flow inward only.
- Each external service (PostgreSQL, LLM provider, Firebase FCM) MUST have
  its own outbound adapter implementing a domain-defined port interface.
- The mobile client (Flutter) MUST implement MVVM + Riverpod:
  - **ViewModel layer** (Riverpod Notifiers): owns all business logic and
    UI state; MUST NOT contain direct API calls or database queries.
  - **Repository layer**: the sole data-access port; abstracts both the
    remote FastAPI backend and the local SQLite database (via Drift).
  - BLoC and Cubit are explicitly forbidden; Riverpod is the only approved
    state-management library.

**Rationale**: Hexagonal architecture directly addresses the project's core
problem of unreliable data by enforcing validation and business rules at the
domain layer, independent of any framework or external service. It also
enables isolated unit testing of all business logic without database or
network dependencies.

### IV. Incremental Delivery

Each user story (US) in `tasks.md` MUST be independently implementable,
testable, and demonstrable. A user story is complete only when its acceptance
scenarios from `spec.md` can be demonstrated end-to-end.

- The P1 user story MUST constitute a working MVP that can be demoed at any
  checkpoint.
- Lower-priority stories MUST NOT break already-completed higher-priority
  stories.
- Commit after each completed task group; do not accumulate uncommitted work
  across multiple tasks.

**Rationale**: Thesis milestones require demonstrable progress at fixed
intervals. Incremental delivery ensures there is always a working version of
the system available for review.

### V. Simplicity (YAGNI)

Implement exactly what is required by the current spec — no more. Abstractions,
generalizations, and framework integrations MUST be justified by an immediate,
concrete requirement documented in `spec.md` or `plan.md`.

- Three similar code blocks are preferred over a premature abstraction.
- Do not add error handling, fallbacks, or validation for scenarios that cannot
  currently occur.
- Configuration and environment variables MUST NOT be added for values that
  never change between environments.

**Rationale**: Over-engineering is the primary risk for a time-boxed academic
project. Complexity must earn its place.

## Technology Stack

**Backend**: Python 3.11+ with FastAPI. PostgreSQL as the primary database.
Architecture: Hexagonal (Ports & Adapters).

**Mobile**: Flutter (Dart). Architecture: MVVM + Riverpod.
- State management: Riverpod (Notifiers). BLoC/Cubit are forbidden.
- Local persistence: Drift (SQLite) — used for offline OT closure queuing
  and any other data that must survive connectivity loss.
- Remote data access: FastAPI REST API consumed via Repository classes.
Framework is fixed for all features; React Native is not in scope.

**Infrastructure & Services**:
- **Deploy**: Railway (FastAPI + PostgreSQL)
- **Push Notifications**: Firebase Cloud Messaging (FCM) — triggered by
  backend events (OT assignment, shift-end reminders, overdue high-priority OTs)
- **File Storage**: Firebase Storage — temporary image storage for the
  communications module (auto-deleted at end of day)

**LLM Integration**: External LLM API (Anthropic or OpenAI) consumed via an
outbound adapter in the backend. Used exclusively for OT description
standardization.

**Testing**:
- Backend: `pytest` with `httpx` for API-layer tests.
- Mobile: Flutter test package.

**API Contract format**: OpenAPI 3.1 (YAML) stored in
`specs/[feature]/contracts/`.

**Constraints**:
- All secrets and environment-specific values MUST use environment variables;
  no hardcoded credentials.
- The mobile app MUST function correctly when backend responses are slow
  (loading states required for all async calls).
- The mobile app MUST store OT registration data locally when offline and
  sync automatically when connectivity is restored.

## Development Workflow

1. **Specify** (`/speckit-specify`): Write `spec.md` with user stories,
   requirements, and acceptance scenarios.
2. **Plan** (`/speckit-plan`): Produce `plan.md`, `data-model.md`,
   `quickstart.md`, and API contracts in `contracts/`.
3. **Tasks** (`/speckit-tasks`): Generate `tasks.md` ordered by priority and
   dependency.
4. **Implement** (`/speckit-implement`): Execute tasks; commit after each
   task group.
5. **Verify**: Run acceptance scenarios from `spec.md` manually or via tests
   before marking a story complete.

**Branch convention**: `[###-feature-name]` (sequential numbering, lowercase
kebab-case). All feature work MUST be on a dedicated branch; direct commits
to `main`/`master` are forbidden.

**Review**: Each feature branch MUST pass a `/code-review` before merging.
Constitution compliance is checked as part of every plan review (Constitution
Check gate in `plan.md`).

## Governance

This constitution supersedes all other project conventions. When a practice
described elsewhere conflicts with a principle here, the constitution takes
precedence. Exceptions require an explicit amendment documented below.

**Amendment procedure**:
1. Propose change in writing (a new feature branch or a dedicated amendment
   branch).
2. Update this file with a new version, revised `LAST_AMENDED_DATE`, and a
   one-line changelog entry.
3. Re-run `/speckit-constitution` to propagate changes to dependent templates.
4. Commit with message: `docs: amend constitution to vX.Y.Z — <summary>`.

**Versioning policy** (semantic):
- MAJOR: Principle removed, renamed, or its core rule reversed.
- MINOR: New principle or section added, or existing principle materially
  extended.
- PATCH: Clarifications, wording, typo fixes.

**Compliance review**: Every `/speckit-plan` run MUST include a Constitution
Check section that explicitly confirms or flags violations for each active
principle. Complexity tracking in `plan.md` is required for any intentional
violation.

**Changelog**:
- 1.0.1 (2026-06-08): Principle III replaced Clean Architecture with Hexagonal
  (Ports & Adapters); Flutter fixed as the sole mobile framework; Technology
  Stack expanded with Railway, Firebase FCM, Firebase Storage, and LLM adapter
  details; offline sync constraint added.
- 1.0.2 (2026-06-08): Sync Impact Report corrected to reflect full 1.0.x history;
  no principle or governance changes.
- 1.1.0 (2026-06-08): Principle III mobile architecture expanded — MVVM + Riverpod
  specified; Drift/SQLite added as offline persistence layer; BLoC/Cubit forbidden;
  Technology Stack updated accordingly.

**Version**: 1.1.0 | **Ratified**: 2026-06-08 | **Last Amended**: 2026-06-08