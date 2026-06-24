---
description: "Task list for User Management Module implementation"
---

# Tasks: User Management Module

**Branch**: `001-user-management` | **Updated**: 2026-06-24
**Input**: Design documents from `specs/001-user-management/`

**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Tests**: Not requested — test tasks omitted per project constitution.

**Organization**: Tasks are grouped by user story. Tasks already completed under
the original spec are marked `[X]`. Tasks that must be corrected to match the
updated spec (5 Supervisors, supervisor-scoped roster, no deletion) are marked
`[ ]` regardless of prior state. Deletion-related tasks T059–T064 are removed.

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
- [X] T008 [P] **Update** abstract `UserRepository` port to add `list_by_supervisor(supervisor_id: UUID) -> list[User]` and `get_by_id_and_supervisor(tech_id: UUID, supervisor_id: UUID) -> User | None` methods alongside the existing ones in `backend/src/domain/ports/user_repository.py`
- [X] T009 [P] Create `UserORM` SQLAlchemy mapped class (table `users`, columns matching data-model.md, `UNIQUE` index on `username`) in `backend/src/adapters/outbound/postgres/orm_models.py`
- [X] T010 **Update** Alembic migration `001_create_users_table.py`: replace the single seed Supervisor row with the 5 real Supervisor accounts (fernando.salazar / Fernando Salazar, gonzalo.orellana / Gonzalo Orellana, ivan.zenteno / Iván Zenteno, consuelo.urquizu / Consuelo Urquizu, eliana.sandoval / Eliana Sandóval); all with `role='supervisor'`, `status='active'`, `created_by_id=NULL`, and `password_hash=bcrypt(SUPERVISOR_PASSWORD env var, default Superv2026) in `backend/alembic/versions/001_create_users_table.py`
- [X] T011 **Update** `PostgresUserRepository` to implement the two new scoped methods added in T008: `list_by_supervisor` filters `WHERE created_by_id = supervisor_id AND role = 'technician'`; `get_by_id_and_supervisor` returns the user only if `id = tech_id AND created_by_id = supervisor_id`, else returns None in `backend/src/adapters/outbound/postgres/user_repository.py`
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

**Goal**: Any of the 5 Supervisors (or a Technician) can log in, their session persists across app restarts, and they can log out.

**Independent Test**: See `quickstart.md` Story 1 — login as `fernando.salazar / Superv2026`, close/reopen app, verify session, log out.

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

**Checkpoint**: US1 complete — login, session persistence across restart, logout all functional. Validate with all 5 Supervisor accounts.

---

## Phase 4: User Story 2 — Supervisor Creates Technician Account (Priority: P2)

**Goal**: Supervisor creates a Technician account; the system records the creating Supervisor as owner (`created_by_id`); Technician logs in with default password COLBO2026.

**Independent Test**: See `quickstart.md` Story 2 — `gonzalo.orellana` creates `carlos.rios`, logs in as that technician, then logs in as `fernando.salazar` and confirms `carlos.rios` is NOT in their list.

### Backend — US2

- [X] T030 [P] [US2] **Update** `create_technician(display_name, username, supervisor_id, user_repo, password_utils, default_password) -> User` use case: add `supervisor_id` parameter and pass it as `created_by_id` when calling `user_repo.create` in `backend/src/domain/use_cases/create_technician.py`
- [X] T031 [US2] **Update** `POST /api/v1/technicians` router to extract `current_user.id` from the `require_supervisor` dependency and pass it as `supervisor_id` to the `create_technician` use case in `backend/src/adapters/inbound/routers/users.py`

### Mobile — US2

- [X] T032 [P] [US2] Create `CreateTechnicianRequest` and `UpdateTechnicianRequest` Dart DTO classes (with `toJson`) in `mobile/lib/data/remote/dtos/user_dto.dart`
- [X] T033 [P] [US2] Create abstract `UserRepository` interface with `createTechnician(username, displayName) -> User` method in `mobile/lib/domain/repositories/user_repository.dart`
- [X] T034 [US2] Implement `UserRepositoryImpl` with `createTechnician` method: call `POST /api/v1/technicians` via Dio, parse `UserProfile` response in `mobile/lib/data/remote/user_repository_impl.dart`
- [X] T035 [US2] Implement `TechnicianListNotifier` as `AsyncNotifier<List<User>>` with `createTechnician(username, displayName)` action that calls repository and refreshes state in `mobile/lib/presentation/viewmodels/technician_list_vm.dart`
- [X] T036 [US2] Implement `CreateTechnicianScreen`: display_name and username text fields, field-level validation (non-empty, 3+ char username), submit button, loading state, error display (including username conflict), success navigation in `mobile/lib/presentation/screens/supervisor/create_technician_screen.dart`
- [X] T037 [US2] Add `userRepositoryProvider` and `technicianListNotifierProvider` to `mobile/lib/core/di.dart`; add `/supervisor/create-technician` route to go_router (Supervisor only)

**Checkpoint**: US2 complete — Technician created with `created_by_id = supervisor.id`. Confirm Technician is visible only in creating Supervisor's list.

---

## Phase 5: User Story 3 — Supervisor Manages Own Technician Roster (Priority: P3)

**Goal**: Each Supervisor sees and manages ONLY their own Technicians. Cross-supervisor access returns 404. Disable/enable cycle works. Permanent deletion is out of scope.

**Independent Test**: See `quickstart.md` Story 3 — including isolation scenarios 8 and 9 (second Supervisor gets 404 and empty list).

### Backend — US3

- [X] T038 [P] [US3] **Update** `list_technicians(supervisor_id, user_repo) -> list[User]` use case: add `supervisor_id` parameter and call `user_repo.list_by_supervisor(supervisor_id)` instead of returning all technicians in `backend/src/domain/use_cases/list_technicians.py`
- [X] T039 [P] [US3] **Update** `update_technician(id, supervisor_id, display_name?, username?, user_repo) -> User` use case: add `supervisor_id` parameter, call `user_repo.get_by_id_and_supervisor(id, supervisor_id)` and raise `TechnicianNotFoundError` if None in `backend/src/domain/use_cases/update_technician.py`
- [X] T040 [US3] **Update** `set_account_status(id, supervisor_id, status, user_repo) -> User` use case: add `supervisor_id` parameter, call `user_repo.get_by_id_and_supervisor(id, supervisor_id)` and raise `TechnicianNotFoundError` if None (still reject supervisor targets with `CannotDisableSupervisorError`) in `backend/src/domain/use_cases/set_account_status.py`
- [X] T041 [US3] **Update** `GET /api/v1/technicians` and `GET /api/v1/technicians/{id}` routers: extract `current_user.id` and pass as `supervisor_id` to `list_technicians` and `get_by_id_and_supervisor`; map `TechnicianNotFoundError` → HTTP 404 in `backend/src/adapters/inbound/routers/users.py`
- [X] T042 [US3] **Update** `PATCH /api/v1/technicians/{id}` and `PATCH /api/v1/technicians/{id}/status` routers: extract `current_user.id` and pass as `supervisor_id` to use cases; map `TechnicianNotFoundError` → HTTP 404; confirm `DELETE /api/v1/technicians/{id}` route does NOT exist in `backend/src/adapters/inbound/routers/users.py`

### Mobile — US3

- [X] T043 [US3] Add `listTechnicians() -> List<User>`, `getTechnician(id) -> User`, `updateTechnician(id, displayName?, username?) -> User`, `setTechnicianStatus(id, status) -> User` methods to `UserRepositoryImpl` in `mobile/lib/data/remote/user_repository_impl.dart`
- [X] T044 [US3] Expand `TechnicianListNotifier` with `loadList()`, `editTechnician(id, displayName?, username?)`, `disableTechnician(id)`, `enableTechnician(id)` actions that update state after each operation in `mobile/lib/presentation/viewmodels/technician_list_vm.dart`
- [X] T045 [US3] Implement `TechnicianListScreen`: scrollable list of technician cards showing name + status chip (Active/Disabled), FAB to create, tap to navigate to detail; loading and error states in `mobile/lib/presentation/screens/supervisor/technician_list_screen.dart`
- [X] T046 [US3] Implement `TechnicianDetailScreen`: display name and username with inline edit form, Disable/Enable toggle button with confirmation dialog, status badge; wire to `TechnicianListNotifier` actions; no delete button in `mobile/lib/presentation/screens/supervisor/technician_detail_screen.dart`
- [X] T047 [US3] Add `/supervisor/technicians` and `/supervisor/technicians/:id` routes to go_router in `mobile/lib/core/router.dart`; add route from Supervisor home to technician list

**Checkpoint**: US3 complete — each Supervisor sees only their group. Isolation scenarios 8 and 9 from quickstart.md confirmed. No delete option visible anywhere.

---

## Phase 6: User Story 4 — Self-Service Profile Management (Priority: P4)

**Goal**: Both roles view and update their own display name and password. Technicians cannot access management screens.

**Independent Test**: See `quickstart.md` Story 4 — update name, change password, verify old password rejected.

### Backend — US4

- [X] T048 [P] [US4] Implement `update_profile(user_id, display_name, user_repo) -> User` use case: validate non-empty display_name, update in DB in `backend/src/domain/use_cases/update_profile.py`
- [X] T049 [P] [US4] Implement `change_password(user_id, current_password, new_password, user_repo, password_utils) -> None` use case: verify current password, enforce 6-char minimum on new password, hash and persist in `backend/src/domain/use_cases/change_password.py`
- [X] T050 [US4] Implement `GET /api/v1/users/me` (return own `UserProfile`), `PATCH /api/v1/users/me` (update display name), `PATCH /api/v1/users/me/password` (change password) routers requiring only `get_current_user` in `backend/src/adapters/inbound/routers/users.py`

### Mobile — US4

- [X] T051 [US4] Add `getMe() -> User`, `updateProfile(displayName) -> User`, `changePassword(currentPassword, newPassword) -> void` methods to `UserRepositoryImpl` in `mobile/lib/data/remote/user_repository_impl.dart`
- [X] T052 [US4] Implement `ProfileNotifier` as `AsyncNotifier<User>`: on build calls `getMe()`, expose `updateDisplayName(name)` and `changePassword(current, next)` methods; propagate API errors to UI in `mobile/lib/presentation/viewmodels/profile_vm.dart`
- [X] T053 [US4] Implement `ProfileScreen`: shows display name (editable inline) and username (read-only), "Change Password" section with current/new password fields, 6-char validation on client, success/error feedback in `mobile/lib/presentation/screens/profile/profile_screen.dart`
- [X] T054 [US4] Add `profileNotifierProvider` to `mobile/lib/core/di.dart`; add `/profile` route to go_router accessible to both roles; add Profile link to both Supervisor and Technician home screens

**Checkpoint**: US4 complete — both roles update display name and password; Technicians cannot navigate to management screens

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Hardening applicable across all stories

- [X] T055 [P] Add structured error handler in `backend/src/main.py` that maps unhandled domain exceptions and `IntegrityError` to JSON `ErrorResponse` with appropriate HTTP status codes
- [X] T056 [P] Ensure every `AsyncNotifier` in mobile shows a `CircularProgressIndicator` in `AsyncLoading` state and a dismissible `SnackBar` for `AsyncError` across all screens
- [X] T057 [P] Add Supervisor-only route guard to go_router so any Technician session navigating to `/supervisor/*` routes is redirected to Technician home in `mobile/lib/core/router.dart`
- [ ] T058 Run all validation scenarios from `specs/001-user-management/quickstart.md` end-to-end — including Story 3 isolation scenarios 8 (404 for foreign technician) and 9 (empty list for second Supervisor) — and verify all acceptance scenarios from `spec.md` pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — T002, T003, T004, T005 can run in parallel
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
  - T008 and T010 must complete before T011 (port before implementation)
  - T011 must complete before any use case that calls the new scoped methods
- **US1 (Phase 3)**: Depends on Foundational — MVP gate; already complete ✅
- **US2 (Phase 4)**: T030 → T031 must complete before testing isolation
- **US3 (Phase 5)**: T038–T042 depend on T008 + T011 from Foundational
- **US4 (Phase 6)**: No new dependencies — already complete ✅
- **Polish (Final)**: T058 depends on all prior tasks complete

### Correction Execution Order

The minimum path to match the updated spec:

```
T008 (port) → T010 (migration) → T011 (repo impl)
                                      ↓
                     T030 (create_technician use case)
                     T038 (list_technicians use case)   ← parallel
                     T039 (update_technician use case)  ← parallel
                         ↓
                     T031 (POST /technicians router)
                     T040 (set_account_status use case) ← parallel
                     T041 (GET /technicians routers)    ← parallel
                     T042 (PATCH routers + remove DELETE) ← parallel
                         ↓
                     T058 (quickstart end-to-end validation)
```

### Parallel Opportunities

```
Correction phase (all can run in parallel after T008 + T011):
  T030 ∥ T038 ∥ T039    (use case updates — different files)

Router updates (after use cases):
  T031 ∥ T040 ∥ T041 ∥ T042    (all in users.py — sequential within file)
```

---

## Implementation Strategy

### Correction-First (Updated Spec)

1. Correct T008 (port) and T011 (repo implementation) — these unblock everything
2. Correct T010 (migration) — re-run seed on Railway after DB cleanup
3. Correct use cases T030, T038, T039, T040 in parallel
4. Correct routers T031, T041, T042 in sequence (same file)
5. Validate with T058 — all quickstart scenarios including isolation

### Already-Done ✅

US1, most of US2 (mobile only), US3 (mobile only), US4, Polish (T055–T057)
are complete and do not need to be redone — they are not affected by
the spec correction.

### Still Needed (in order)

T008 → T010 → T011 → T030 → T031 → T038 → T039 → T040 → T041 → T042 → T058

---

## Notes

- `[P]` tasks can be executed concurrently (different files, no shared state)
- `[US#]` label traces each task back to its user story
- **Deleted tasks T059–T064** (delete_technician backend + mobile) are removed from scope; the `delete_technician.py` use case file and any `DELETE /technicians/{id}` router must also be removed if they exist
- The supervisor isolation invariant MUST be enforced at the **use-case layer** (via `get_by_id_and_supervisor`), not only in the router
- After correcting T010, run `DELETE FROM users WHERE true;` on Railway before re-running `alembic upgrade head` to re-seed with the 5 real Supervisors
- The `created_by_id` field is set once at Technician creation and is immutable — do not expose it to the API caller
