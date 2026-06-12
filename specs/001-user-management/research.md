# Research: User Management Module

**Feature**: `001-user-management` | **Date**: 2026-06-08

## 1. JWT Token Strategy

**Decision**: Single short-lived access token (24-hour TTL), stored in
`flutter_secure_storage` on the device. No refresh tokens.

**Rationale**: The spec requires session persistence across app restarts (FR-002) and
immediate session invalidation on account disable (FR-008). A 24-hour TTL satisfies
persistence without needing a refresh flow. Invalidation is enforced server-side: the
FastAPI `get_current_user` dependency decodes the JWT, then queries the DB to verify
`user.status == active` on every protected request. A disabled user's next API call
returns HTTP 401, and the mobile app redirects to login.

**Alternatives considered**:
- Refresh token pair: rejected (YAGNI — adds significant complexity with a rotation
  endpoint, refresh token storage, and revocation list, none of which adds user value at
  this scale).
- Token blacklist: rejected (requires a shared Redis store or DB table, adds latency to
  every auth check; the per-request status DB lookup is simpler and sufficient).
- Very short TTL (15 min) with background refresh: rejected (poor UX for offline/low
  connectivity scenarios and adds mobile complexity; the spec explicitly states offline
  auth is out of scope).

## 2. Password Hashing

**Decision**: `passlib[bcrypt]` with the default cost factor (12 rounds). Passwords
validated in the domain use case layer (minimum 6 characters, FR-012).

**Rationale**: bcrypt is the industry standard for password hashing in Python web
applications, provides adaptive cost, and is natively supported by passlib. The domain
layer validates length before the hash is computed, keeping validation logic out of the
adapter.

**Default password handling**: The string `COLBO2026` is never stored in source code or
config files. It is hashed at seed time in the Alembic seed migration, and the resulting
hash is the only value persisted. An environment variable `DEFAULT_TECHNICIAN_PASSWORD`
can override it for test environments.

**Alternatives considered**:
- Argon2: technically superior but passlib bcrypt integration is better documented and
  more common in FastAPI tutorials the team references.
- SHA-256: rejected (not a password hashing function — lacks salting and adaptive cost).

## 3. Session Persistence on Mobile

**Decision**: `flutter_secure_storage` writes the JWT string to the platform keychain
(iOS Keychain / Android Keystore). On app start, `AuthNotifier` reads the token, checks
its expiry client-side, and if valid calls `GET /api/v1/users/me` to restore the
session. If the server returns 401 (account disabled or token expired), the notifier
transitions to the unauthenticated state and go_router redirects to login.

**Rationale**: `flutter_secure_storage` uses hardware-backed secure storage on both
platforms, is the Flutter community standard for token persistence, and requires no
additional Android permissions. The `GET /me` call on start also catches the "account
disabled" case immediately, satisfying FR-008.

**Alternatives considered**:
- `SharedPreferences`: rejected (stores plaintext on Android; not suitable for tokens).
- `hive` encrypted box: rejected (adds a dependency and encryption key management
  overhead for a single value that `flutter_secure_storage` handles natively).

## 4. Role-Based Access Control (RBAC)

**Decision**: Two-tier RBAC enforced at both backend and mobile layers.

Backend: The `get_current_user` FastAPI dependency returns the full `User` domain model
including role. Supervisor-only endpoints use a second dependency
`require_supervisor(user = Depends(get_current_user))` that raises HTTP 403 if
`user.role != Role.supervisor`. Domain use cases also enforce role constraints (e.g.,
`set_account_status` rejects attempts to disable a Supervisor regardless of caller role).

Mobile: `go_router` redirect logic checks `AuthNotifier` state and user role before
allowing navigation to any screen. Technician sessions cannot reach supervisor routes
even if a URL is manually entered.

**Alternatives considered**:
- Permission-based system (enumerate permissions): rejected (YAGNI — two static roles
  with clear boundaries do not require a permission table).
- Middleware-level role check: rejected in favour of dependency injection — easier to
  test use cases independently.

## 5. Username Uniqueness and Conflict Handling

**Decision**: PostgreSQL `UNIQUE` constraint on `users.username`. The SQLAlchemy
outbound adapter catches `IntegrityError` on insert/update and re-raises it as a domain
`UsernameAlreadyExistsError`. The FastAPI router maps this to HTTP 409 Conflict with a
user-readable message.

**Rationale**: The DB constraint guarantees uniqueness even under concurrent writes.
Translating the constraint error at the adapter boundary keeps the domain use case clean
(no pre-check query needed).

## 6. Account Disable — Concurrent Session Handling

**Decision**: Disabling an account updates `users.status = disabled` in the DB. The
next authenticated request from that user hits the `get_current_user` dependency, which
queries the DB and finds `status = disabled`, and raises HTTP 401. The mobile
`AuthNotifier` catches the 401 from the Dio interceptor, clears the stored token, and
triggers a navigation redirect to login.

**Timing**: The Supervisor's PATCH call completes in < 1 s. The Technician's mobile
client detects the disable on their next API call. In an active session this happens
within seconds. This satisfies SC-003 ("within 5 seconds") for any app that is actively
making requests; idle apps detect it on the next interaction.

**Alternatives considered**:
- WebSocket push to force logout: rejected (adds infrastructure complexity beyond scope).
- Polling: rejected (wasteful; the per-request check is sufficient).
