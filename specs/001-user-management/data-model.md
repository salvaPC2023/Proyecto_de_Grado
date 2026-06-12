# Data Model: User Management Module

**Feature**: `001-user-management` | **Date**: 2026-06-08

## Backend — PostgreSQL

### Entity: `User`

The sole entity in this module. Represents any authenticated system account.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | UUID | PRIMARY KEY, default gen_random_uuid() | |
| `username` | VARCHAR(50) | NOT NULL, UNIQUE | Login identifier; set at creation |
| `display_name` | VARCHAR(100) | NOT NULL | Editable by owner and Supervisor |
| `password_hash` | VARCHAR(255) | NOT NULL | bcrypt hash |
| `role` | VARCHAR(50) | NOT NULL | Immutable after creation; values: 'supervisor', 'technician' |
| `status` | VARCHAR(50) | NOT NULL, DEFAULT 'active' | Supervisor-managed; values: 'active', 'disabled' |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT now() | |
| `created_by_id` | UUID | FK → users.id, NULLABLE | NULL for the seeded Supervisor |

**Indexes**:
- `UNIQUE (username)` — enforces uniqueness for login lookups
- `INDEX (status)` — fast filter for disabled-account check in auth dependency

**Validation rules** (enforced in domain use case layer, not only in DB):
- `username`: 3–50 characters, alphanumeric + underscore + hyphen only, case-insensitive
  uniqueness check (stored lowercase)
- `display_name`: 1–100 characters, non-empty after trim
- `password` (pre-hash): minimum 6 characters
- `role`: only `technician` may be created via the API; `supervisor` role is seeded only
- `status`: only `technician` accounts may be disabled via the API
- `role` and `status` use `VARCHAR(50)` instead of a PostgreSQL native ENUM type; valid
  values are enforced at the application layer (domain use cases + Pydantic models) to
  avoid migration complexity when adding new values in future iterations

### State Transitions

```
User status:
  active ──[Supervisor disables]──► disabled
  disabled ──[Supervisor re-enables]──► active

  Supervisor accounts: no transitions allowed (status always 'active' from API)

User deletion:
  active|disabled ──[Supervisor deletes, no work orders]──► permanently removed
  active|disabled ──[Supervisor deletes, has work orders]──► rejected (409)
  Supervisor accounts: deletion blocked (400)
```

### Seed Data (Alembic seed migration)

```
username:       admin          (or configurable via SUPERVISOR_USERNAME env var)
display_name:   Supervisor
role:           supervisor
status:         active
password_hash:  bcrypt(SUPERVISOR_PASSWORD env var, default: 'Admin2026')
created_by_id:  NULL
```

The default Technician password `COLBO2026` is never stored directly; it is hashed at
account creation time by the `create_technician` use case using the value of the
`DEFAULT_TECHNICIAN_PASSWORD` environment variable.

---

## Mobile — Flutter (No local DB for this module)

This module does not use Drift/SQLite. Authentication requires an active internet
connection (per spec assumption). The only local persistence is the JWT string in
`flutter_secure_storage`.

### Secure Storage Key

| Key | Value |
|-----|-------|
| `auth_token` | Raw JWT string (written on login, deleted on logout) |

### Domain Models (pure Dart)

**`User`**

```
id:           String (UUID)
username:     String
displayName:  String
role:         Role (supervisor | technician)
status:       UserStatus (active | disabled)
```

**`Role`** (enum)
```
supervisor
technician
```

**`UserStatus`** (enum)
```
active
disabled
```

**`AuthSession`** (ephemeral, held in AuthNotifier state)
```
user:   User
token:  String (JWT)
```

### ViewModel States

**`AuthState`** (Riverpod `AsyncNotifier<AuthSession?>`)

| State | Meaning |
|-------|---------|
| `AsyncLoading` | App startup — reading token from secure storage |
| `AsyncData(null)` | Unauthenticated — show login screen |
| `AsyncData(AuthSession)` | Authenticated — allow navigation |
| `AsyncError` | Login failure — show error on login screen |

**`TechnicianListState`** (Riverpod `AsyncNotifier<List<User>>`)

| State | Meaning |
|-------|---------|
| `AsyncLoading` | Fetching technician list |
| `AsyncData(list)` | List loaded |
| `AsyncError` | Network or permission error |

---

## API ↔ Mobile Mapping

| Backend field | Mobile `User` field | Notes |
|---------------|---------------------|-------|
| `id` | `id` | |
| `username` | `username` | |
| `display_name` | `displayName` | camelCase on mobile |
| `role` | `role` | parsed to `Role` enum |
| `status` | `status` | parsed to `UserStatus` enum |
| `created_at` | — | not displayed in mobile UI |
| `created_by_id` | — | not displayed in mobile UI |
