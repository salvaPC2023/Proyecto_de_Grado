---
description: "Task list for User Management Module implementation"
---

# Tasks: User Management Module

**Input**: Design documents from `specs/001-user-management/`

**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Tests**: Not requested — test tasks omitted per project constitution.

**Organization**: Tasks are grouped by user story to enable independent implementation
and testing of each story.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- All descriptions include exact file paths

## Path Conventions

- Backend: `backend/src/` — hexagonal layout (domain/, adapters/inbound/, adapters/outbound/)
- Mobile: `mobile/lib/` — layered layout (core/, data/, domain/, presentation/)

---

## Phase 1: Setup

**Purpose**: Monorepo structure and project initialization

- [X] T001 Create `backend/` and `mobile/` directories with the folder tree defined in plan.md
- [X] T002 [P] Initialize Python backend project: create `backend/pyproject.toml` with FastAPI, SQLAlchemy[asyncio], Alembic, python-jose[cryptography], passlib[bcrypt], pydantic-settings, asyncpg, uvicorn as dependencies
- [X] T003 [P] Initialize Flutter mobile project in `mobile/` and add to `mobile/pubspec.yaml`: riverpod, flutter_riverpod, drift, drift_flutter, dio, go_router, flutter_secure_storage, connectivity_plus, freezed_annotation, json_annotation (dev: build_runner, freezed, json_serializable, drift_dev)
- [X] T004 [P] Create pydantic-settings config class with DATABASE_URL, JWT_SECRET_KEY, JWT_EXPIRE_HOURS (default 24), DEFAULT_TECHNICIAN_PASSWORD (default COLBO2026) in `backend/src/config.py`
- [X] T005 [P] Configure Alembic: initialise with `alembic init alembic` inside `backend/`, set async SQLAlchemy URL in `backend/alembic/env.py` pointing to the config DATABASE_URL

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before any user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Backend Foundation

- [X] T006 Create async SQLAlchemy engine and `AsyncSession` factory using DATABASE_URL from config in `backend/src/adapters/outbound/postgres/database.py`
- [X] T007 Create `User` dataclass with fields (id UUID, username str, display_name str, password_hash str, role Role, status UserStatus, created_at datetime, created_by_id UUID | None); create `Role` (supervisor, technician) and `UserStatus` (active, disabled) enums in `backend/src/domain/models/user.py`
- [X] T008 [P] Create abstract `UserRepository` port with async methods: `get_by_id`, `get_by_username`, `create`, `update_display_name`, `update_username`, `update_password_hash`, `set_status`, `list_technicians` in `backend/src/domain/ports/user_repository.py`
- [X] T009 [P] Create `UserORM` SQLAlchemy mapped class (table `users`, columns matching data-model.md, `UNIQUE` index on `username`) in `backend/src/adapters/outbound/postgres/orm_models.py`
- [X] T010 Create Alembic migration `001_create_users_table.py` in `backend/alembic/versions/`: create `users` table with all columns from data-model.md plus a seed `INSERT` for the Supervisor account using `DEFAULT_TECHNICIAN_PASSWORD` env var (bcrypt-hashed at migration time)
- [X] T011 Implement `PostgresUserRepository` that inherits `UserRepository` and implements all methods using `AsyncSession` and `UserORM` in `backend/src/adapters/outbound/postgres/user_repository.py`
- [X] T012 [P] Create `create_access_token(user_id, role) -> str` and `decode_access_token(token) -> dict` using python-jose with JWT_SECRET_KEY and JWT_EXPIRE_HOURS from config in `backend/src/adapters/inbound/jwt_utils.py`
- [X] T013 [P] Create `hash_password(plain: str) -> str` and `verify_password(plain: str, hashed: str) -> bool` using passlib bcrypt in `backend/src/adapters/inbound/password_utils.py`
- [X] T014 Create `get_current_user` FastAPI dependency (decode JWT → fetch user from DB → reject if status=disabled with HTTP 401) and `require_supervisor` dependency (reject if role≠supervisor with HTTP 403) in `backend/src/adapters/inbound/dependencies.py`
- [X] T015 Create FastAPI application with lifespan (DB engine init), CORS middleware, and router include stubs in `backend/src/main.py`

### Mobile Foundation

- [X] T016 [P] Create `User`, `Role` (enum), `UserStatus` (enum) pure Dart domain classes (no Flutter/Drift imports) in `mobile/lib/domain/models/user.dart`
- [X] T017 [P] Create `TokenStorage` class wrapping `flutter_secure_storage` with `write(token)`, `read() -> String?`, `delete()` methods using the `auth_token` key in `mobile/lib/data/local/token_storage.dart`
- [X] T018 [P] Create Dio `ApiClient` with base URL (from env/build config), `AuthInterceptor` that attaches `Authorization: Bearer <token>` header from `TokenStorage` and forwards 401 errors for the notifier to handle in `mobile/lib/data/remote/api_client.dart`
- [X] T019 Create go_router `AppRouter` with routes: `/login`, `/supervisor/home`, `/technician/home`; add redirect guard that reads `AuthNotifier` state and routes unauthenticated users to `/login` in `mobile/lib/core/router.dart`
- [X] T020 Create Riverpod provider declarations: `apiClientProvider`, `tokenStorageProvider`, `authNotifierProvider` (stub — filled in Phase 3), `routerProvider` in `mobile/lib/core/di.dart`

**Checkpoint**: Foundation ready — all user story implementation can now begin in parallel

---

## Phase 3: User Story 1 — Authentication & Session Management (Priority: P1) 🎯 MVP

**Goal**: Any user can log in, their session persists across app restarts, and they can log out.

**Independent Test**: See `quickstart.md` Story 1 section — login as Supervisor, close/reopen app, verify session, log out.

### Backend — US1

- [X] T021 [P] [US1] Implement `authenticate(username, password, user_repo, password_utils, jwt_utils) -> (User, token_str)` use case: fetch user by username, verify password, reject if disabled, return User + signed JWT in `backend/src/domain/use_cases/authenticate.py`
- [X] T022 [US1] Implement `POST /api/v1/auth/login` router: call `authenticate` use case, return `LoginResponse` (access_token, token_type, user summary) per `contracts/auth.yaml` schema in `backend/src/adapters/inbound/routers/auth.py`
- [X] T023 [US1] Implement `POST /api/v1/auth/logout` router: require valid token via `get_current_user`, return HTTP 204 in `backend/src/adapters/inbound/routers/auth.py`; register auth router in `backend/src/main.py`

### Mobile — US1

- [X] T024 [P] [US1] Create `LoginRequest` and `LoginResponse` Dart classes (with `fromJson`/`toJson`) matching `contracts/auth.yaml` in `mobile/lib/data/remote/dtos/auth_dto.dart`
- [X] T025 [P] [US1] Create abstract `AuthRepository` interface with `login(username, password) -> AuthSession`, `logout()`, `restoreSession() -> AuthSession?` in `mobile/lib/domain/repositories/auth_repository.dart`
- [X] T026 [US1] Implement `AuthRepositoryImpl`: `login` calls `POST /api/v1/auth/login` via Dio, writes token to `TokenStorage`, returns `AuthSession`; `logout` calls `POST /api/v1/auth/logout` and deletes token; `restoreSession` reads token, calls `GET /api/v1/users/me`, returns `AuthSession` or null in `mobile/lib/data/remote/auth_repository_impl.dart`
- [X] T027 [US1] Implement `AuthNotifier` as `AsyncNotifier<AuthSession?>`: on build calls `restoreSession()`, expose `login(username, password)` and `logout()` methods; on 401 from any API call clear token and set state to null in `mobile/lib/presentation/viewmodels/auth_vm.dart`
- [X] T028 [US1] Implement `LoginScreen`: username + password text fields, submit button, loading indicator during login, error snackbar on failure; on success go_router navigates to role-appropriate home in `mobile/lib/presentation/screens/auth/login_screen.dart`
- [X] T029 [US1] Wire `authRepositoryProvider` and `authNotifierProvider` in `mobile/lib/core/di.dart`; update go_router redirect guard to read `authNotifierProvider` state

**Checkpoint**: US1 complete — login, session persistence across restart, logout all functional end-to-end

---

## Phase 4: User Story 2 — Supervisor Creates Technician Account (Priority: P2)

**Goal**: Supervisor creates a Technician account; Technician logs in with default password COLBO2026.

**Independent Test**: See `quickstart.md` Story 2 section — create account, log in as Technician.

### Backend — US2

- [X] T030 [P] [US2] Implement `create_technician(display_name, username, user_repo, password_utils, default_password) -> User` use case: validate fields, hash `default_password`, call `user_repo.create`, raise `UsernameAlreadyExistsError` on duplicate in `backend/src/domain/use_cases/create_technician.py`
- [X] T031 [US2] Implement `POST /api/v1/technicians` router: require `require_supervisor`, call `create_technician` use case, return HTTP 201 with `UserProfile` response; map `UsernameAlreadyExistsError` to HTTP 409 per `contracts/users.yaml` in `backend/src/adapters/inbound/routers/users.py`; register users router in `backend/src/main.py`

### Mobile — US2

- [X] T032 [P] [US2] Create `CreateTechnicianRequest` and `UpdateTechnicianRequest` Dart DTO classes (with `toJson`) in `mobile/lib/data/remote/dtos/user_dto.dart`; `UserProfile` deserialization is handled directly by domain `User.fromJson()` — no separate DTO class needed
- [X] T033 [P] [US2] Create abstract `UserRepository` interface with `createTechnician(username, displayName) -> User` method in `mobile/lib/domain/repositories/user_repository.dart`
- [X] T034 [US2] Implement `UserRepositoryImpl` with `createTechnician` method: call `POST /api/v1/technicians` via Dio, parse `UserProfile` response in `mobile/lib/data/remote/user_repository_impl.dart`
- [X] T035 [US2] Implement `TechnicianListNotifier` as `AsyncNotifier<List<User>>` with `createTechnician(username, displayName)` action that calls repository and refreshes state in `mobile/lib/presentation/viewmodels/technician_list_vm.dart`
- [X] T036 [US2] Implement `CreateTechnicianScreen`: display_name and username text fields, field-level validation (non-empty, 3+ char username), submit button, loading state, error display (including username conflict), success navigation in `mobile/lib/presentation/screens/supervisor/create_technician_screen.dart`
- [X] T037 [US2] Add `userRepositoryProvider` and `technicianListNotifierProvider` to `mobile/lib/core/di.dart`; add `/supervisor/create-technician` route to go_router (Supervisor only)

**Checkpoint**: US2 complete — Supervisor creates account, Technician logs in with COLBO2026

---

## Phase 5: User Story 3 — Supervisor Manages Technician Roster (Priority: P3)

**Goal**: Supervisor views, edits, disables, and re-enables Technician accounts; disabled accounts cannot authenticate.

**Independent Test**: See `quickstart.md` Story 3 section — list, edit name, disable (verify blocked), re-enable.

### Backend — US3

- [X] T038 [P] [US3] Implement `list_technicians(user_repo) -> list[User]` use case: return all users with role=technician in `backend/src/domain/use_cases/list_technicians.py`
- [X] T039 [P] [US3] Implement `update_technician(id, display_name?, username?, user_repo) -> User` use case: apply provided fields, raise `UsernameAlreadyExistsError` on duplicate username in `backend/src/domain/use_cases/update_technician.py`
- [X] T040 [US3] Implement `set_account_status(id, status, user_repo) -> User` use case: reject if target user role=supervisor with `CannotDisableSupervisorError`; update status in `backend/src/domain/use_cases/set_account_status.py`
- [X] T041 [US3] Implement `GET /api/v1/technicians` and `GET /api/v1/technicians/{id}` routers (require_supervisor) calling `list_technicians` and fetching by id in `backend/src/adapters/inbound/routers/users.py`
- [X] T042 [US3] Implement `PATCH /api/v1/technicians/{id}` and `PATCH /api/v1/technicians/{id}/status` routers (require_supervisor) calling use cases; map `CannotDisableSupervisorError` → HTTP 400 per `contracts/users.yaml` in `backend/src/adapters/inbound/routers/users.py`
- [X] T059 [P] [US3] Add `TechnicianHasWorkOrdersError` exception class and abstract `delete(user_id: UUID) -> None` method to `UserRepository` port in `backend/src/domain/ports/user_repository.py` (extends T008)
- [X] T060 [P] [US3] Implement `delete_technician(id, user_repo) -> None` use case: fetch user, raise `CannotDeleteSupervisorError` if role=supervisor, call `user_repo.delete(id)` in `backend/src/domain/use_cases/delete_technician.py`; `user_repo.delete` enforces `TechnicianHasWorkOrdersError` before removing the row
- [X] T061 [US3] Implement `DELETE /api/v1/technicians/{tech_id}` router (require_supervisor, HTTP 204): call `delete_technician` use case; map `CannotDeleteSupervisorError` → HTTP 400, `TechnicianHasWorkOrdersError` → HTTP 409, `ValueError` → HTTP 404 in `backend/src/adapters/inbound/routers/users.py`

### Mobile — US3

- [X] T043 [US3] Add `listTechnicians() -> List<User>`, `getTechnician(id) -> User`, `updateTechnician(id, displayName?, username?) -> User`, `setTechnicianStatus(id, status) -> User` methods to `UserRepositoryImpl` in `mobile/lib/data/remote/user_repository_impl.dart`
- [X] T044 [US3] Expand `TechnicianListNotifier` with `loadList()`, `editTechnician(id, displayName?, username?)`, `disableTechnician(id)`, `enableTechnician(id)` actions that update state after each operation in `mobile/lib/presentation/viewmodels/technician_list_vm.dart`
- [X] T045 [US3] Implement `TechnicianListScreen`: scrollable list of technician cards showing name + status chip (Active/Disabled), FAB to create, tap to navigate to detail; loading and error states in `mobile/lib/presentation/screens/supervisor/technician_list_screen.dart`
- [X] T046 [US3] Implement `TechnicianDetailScreen`: display name and username with inline edit form, Disable/Enable toggle button with confirmation dialog, status badge; wire to `TechnicianListNotifier` actions in `mobile/lib/presentation/screens/supervisor/technician_detail_screen.dart`
- [X] T047 [US3] Add `/supervisor/technicians` and `/supervisor/technicians/:id` routes to go_router in `mobile/lib/core/router.dart`; add route from Supervisor home to technician list
- [X] T062 [P] [US3] Add `deleteTechnician(String id) -> void` method to abstract `UserRepository` interface in `mobile/lib/domain/repositories/user_repository.dart`
- [X] T063 [US3] Implement `UserRepositoryImpl.deleteTechnician(id)`: call `DELETE /api/v1/technicians/$id` via Dio in `mobile/lib/data/remote/user_repository_impl.dart`
- [X] T064 [US3] Add `deleteTechnician(String id)` action to `TechnicianListNotifier` that calls repository and refreshes the list; propagate 409 conflict error to UI in `mobile/lib/presentation/viewmodels/technician_list_vm.dart`

**Checkpoint**: US3 complete — roster list, edit, disable/enable, delete; disabled account rejected on next API call

---

## Phase 6: User Story 4 — Self-Service Profile Management (Priority: P4)

**Goal**: Both roles view and update their own display name and password. Technicians cannot access management screens.

**Independent Test**: See `quickstart.md` Story 4 section — update name, change password, verify old password rejected.

### Backend — US4

- [X] T048 [P] [US4] Implement `update_profile(user_id, display_name, user_repo) -> User` use case: validate non-empty display_name, update in DB in `backend/src/domain/use_cases/update_profile.py`
- [X] T049 [P] [US4] Implement `change_password(user_id, current_password, new_password, user_repo, password_utils) -> None` use case: verify current password, enforce 6-char minimum on new password, hash and persist in `backend/src/domain/use_cases/change_password.py`
- [X] T050 [US4] Implement `GET /api/v1/users/me` (return own `UserProfile`), `PATCH /api/v1/users/me` (update display name), `PATCH /api/v1/users/me/password` (change password) routers requiring only `get_current_user` in `backend/src/adapters/inbound/routers/users.py`

### Mobile — US4

- [X] T051 [US4] Add `getMe() -> User`, `updateProfile(displayName) -> User`, `changePassword(currentPassword, newPassword) -> void` methods to `UserRepositoryImpl` in `mobile/lib/data/remote/user_repository_impl.dart`
- [X] T052 [US4] Implement `ProfileNotifier` as `AsyncNotifier<User>`: on build calls `getMe()`, expose `updateDisplayName(name)` and `changePassword(current, next)` methods; propagate API errors to UI in `mobile/lib/presentation/viewmodels/profile_vm.dart`
- [X] T053 [US4] Implement `ProfileScreen`: shows display name (editable inline) and username (read-only), "Change Password" section with current/new password fields, 6-char validation on client, success/error feedback in `mobile/lib/presentation/screens/profile/profile_screen.dart`
- [X] T054 [US4] Add `profileNotifierProvider` to `mobile/lib/core/di.dart`; add `/profile` route to go_router accessible to both roles; add Profile link to both Supervisor and Technician home screens

**Checkpoint**: US4 complete — both roles can update display name and password; Technicians cannot navigate to management screens

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Hardening applicable across all stories

- [X] T055 [P] Add structured error handler in `backend/src/main.py` that maps unhandled domain exceptions and `IntegrityError` to JSON `ErrorResponse` with appropriate HTTP status codes
- [X] T056 [P] Ensure every `AsyncNotifier` in mobile shows a `CircularProgressIndicator` in `AsyncLoading` state and a dismissible `SnackBar` for `AsyncError` across all screens
- [X] T057 [P] Add Supervisor-only route guard to go_router so any Technician session navigating to `/supervisor/*` routes is redirected to Technician home in `mobile/lib/core/router.dart`
- [X] T058 Run all validation scenarios from `specs/001-user-management/quickstart.md` end-to-end and verify all acceptance scenarios from `spec.md` pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately; T002, T003, T004, T005 can run in parallel
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
  - Backend: T006 → T007 → {T008 ∥ T009} → T010 → T011; {T012 ∥ T013} → T014 → T015
  - Mobile: {T016 ∥ T017 ∥ T018} → T019 → T020
- **US1 (Phase 3)**: Depends on Foundational — MVP gate
- **US2 (Phase 4)**: Depends on Foundational; integrates with US1 auth
- **US3 (Phase 5)**: Depends on Foundational + US2 (Technician accounts must exist to test disable)
- **US4 (Phase 6)**: Depends on Foundational; shares router file with US2/US3
- **Polish (Final)**: Depends on all stories complete

### User Story Dependencies

- **US1 (P1)**: Can start immediately after Foundational — no story dependencies
- **US2 (P2)**: Can start after Foundational — no story dependencies (but best validated after US1)
- **US3 (P3)**: Can start after Foundational — practically needs US2 accounts to demonstrate disable
- **US4 (P4)**: Can start after Foundational — no story dependencies

### Within Each User Story

- Backend use case → Backend router → Mobile DTO → Mobile repository interface → Mobile repository impl → Mobile notifier → Mobile screen
- Models before services; services before routers; routers before mobile screens

### Parallel Opportunities

```
Phase 1:  T002 ∥ T003 ∥ T004 ∥ T005

Phase 2 backend:
  T007 → T008 ∥ T009     (port and ORM in parallel after domain model)
  T012 ∥ T013             (JWT utils and password utils in parallel)

Phase 2 mobile:
  T016 ∥ T017 ∥ T018     (domain models, token storage, Dio client in parallel)

Phase 3:
  T021 ∥ T024 ∥ T025     (use case, DTOs, repository interface in parallel)

Phase 4:
  T030 ∥ T032 ∥ T033     (use case, DTOs, repository interface in parallel)

Phase 5:
  T038 ∥ T039             (list and update use cases in parallel)

Phase 6:
  T048 ∥ T049             (update_profile and change_password use cases in parallel)
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational ← **CRITICAL: blocks everything**
3. Complete Phase 3: US1 — Authentication
4. **STOP and VALIDATE**: Run Story 1 scenarios from `quickstart.md`
5. Both roles can log in, session persists, logout works → MVP achieved

### Incremental Delivery

1. Setup + Foundational → infrastructure ready
2. US1 → any user can authenticate → **demo-able milestone**
3. US2 → Supervisor can onboard Technicians → **demo-able milestone**
4. US3 → Supervisor manages roster, can disable accounts → **demo-able milestone**
5. US4 → Users self-manage profiles → **complete module**
6. Polish → production-ready

---

## Notes

- `[P]` tasks can be executed concurrently by different contexts (different files, no shared state)
- `[US#]` label traces each task back to its user story for scope control
- The `get_current_user` dependency established in T014 is reused by all subsequent features
- The `require_supervisor` dependency from T014 is shared by US2, US3, and any future Supervisor-only endpoints
- Commit after each checkpoint; do not accumulate work across multiple stories
