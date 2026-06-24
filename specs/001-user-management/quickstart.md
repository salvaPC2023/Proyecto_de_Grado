# Quickstart & Validation Guide: User Management Module

**Feature**: `001-user-management` | **Date**: 2026-06-08

This guide describes how to validate that each user story works end-to-end after
implementation. It is a run/test guide, not an implementation reference.

## Prerequisites

- Backend running locally or on Railway with PostgreSQL connected
- Alembic migrations applied (including seed migration for the Supervisor account)
- Flutter app built and running on a simulator/device connected to the backend
- Environment variables set: `JWT_SECRET_KEY`, `DATABASE_URL`,
  `DEFAULT_TECHNICIAN_PASSWORD` (optional, defaults to `COLBO2026`)
- HTTP client (curl, httpie, or Postman) for direct API testing

---

## Story 1 — Authentication & Session Management (P1)

### Backend validation (curl)

```bash
# 1. Login with a seeded Supervisor account
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "fernando.salazar", "password": "Superv2026"}'
# Expected: 200 with access_token + user.role = "supervisor"

# 2. Login with wrong password
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "fernando.salazar", "password": "wrongpass"}'
# Expected: 401

# 3. Access protected endpoint with token
TOKEN="<paste access_token from step 1>"
curl http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer $TOKEN"
# Expected: 200 with Supervisor profile

# 4. Logout
curl -X POST http://localhost:8000/api/v1/auth/logout \
  -H "Authorization: Bearer $TOKEN"
# Expected: 204
```

### Mobile validation

1. Open the app → login screen appears.
2. Enter Supervisor credentials → home screen with Supervisor role navigation appears.
3. Close and reopen the app → home screen shown directly (no re-login).
4. Tap Logout → login screen appears, reopening the app shows login screen again.

---

## Story 2 — Supervisor Creates Technician Account (P2)

### Backend validation

```bash
TOKEN="<Supervisor JWT>"

# 1. Create technician
curl -X POST http://localhost:8000/api/v1/technicians \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username": "carlos.rios", "display_name": "Carlos Ríos"}'
# Expected: 201 with user.role = "technician", status = "active"

# 2. Login as new technician with default password
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "carlos.rios", "password": "COLBO2026"}'
# Expected: 200 with access_token

# 3. Duplicate username
curl -X POST http://localhost:8000/api/v1/technicians \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username": "carlos.rios", "display_name": "Another User"}'
# Expected: 409 Conflict

# 4. Missing field
curl -X POST http://localhost:8000/api/v1/technicians \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username": "incomplete"}'
# Expected: 422
```

### Mobile validation

1. Log in as Supervisor → navigate to "Technicians" → tap "Create".
2. Fill in display name and username → confirm → success toast shown.
3. Log out → log in as new technician with password `COLBO2026` → access granted.

---

## Story 3 — Supervisor Manages Technician Roster (P3)

### Backend validation

```bash
TECH_ID="<id from Story 2>"
TOKEN="<Supervisor JWT>"

# 1. List technicians
curl http://localhost:8000/api/v1/technicians \
  -H "Authorization: Bearer $TOKEN"
# Expected: 200 array containing carlos.rios with status "active"

# 2. Edit display name
curl -X PATCH http://localhost:8000/api/v1/technicians/$TECH_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"display_name": "Carlos Ríos Actualizado"}'
# Expected: 200 with updated display_name

# 3. Disable account
curl -X PATCH http://localhost:8000/api/v1/technicians/$TECH_ID/status \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "disabled"}'
# Expected: 200 with status = "disabled"

# 4. Disabled technician cannot log in
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "carlos.rios", "password": "COLBO2026"}'
# Expected: 403 with disabled account message

# 5. Disabled technician's active token is rejected
TECH_TOKEN="<technician JWT obtained before disabling>"
curl http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer $TECH_TOKEN"
# Expected: 401 (status check fails in get_current_user dependency)

# 6. Re-enable account
curl -X PATCH http://localhost:8000/api/v1/technicians/$TECH_ID/status \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "active"}'
# Expected: 200 with status = "active"

# 7. Cannot disable Supervisor account
SUPERVISOR_ID="<Supervisor user id>"
curl -X PATCH http://localhost:8000/api/v1/technicians/$SUPERVISOR_ID/status \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "disabled"}'
# Expected: 400 with "Supervisor accounts cannot be disabled"

# 8. Supervisor isolation — other supervisor's technician returns 404
TOKEN2="<JWT for gonzalo.orellana>"
curl http://localhost:8000/api/v1/technicians/$TECH_ID \
  -H "Authorization: Bearer $TOKEN2"
# Expected: 404 (carlos.rios belongs to fernando.salazar, not gonzalo.orellana)

# 9. List for second supervisor returns empty (no technicians created under them)
curl http://localhost:8000/api/v1/technicians \
  -H "Authorization: Bearer $TOKEN2"
# Expected: 200 with empty array []
```

### Mobile validation

1. Log in as `fernando.salazar` → view technician list → confirm carlos.rios is listed as Active.
2. Tap technician → edit display name → save → list reflects updated name.
3. Tap "Disable" → confirm → technician status shows Disabled.
4. On the Technician's device (if testing with two devices): next action redirects to login.
5. Re-enable from Supervisor → Technician can log in again.
6. Log out → log in as `gonzalo.orellana` → technician list is empty (isolation validated).

---

## Story 4 — Self-Service Profile Management (P4)

### Backend validation

```bash
TECH_TOKEN="<Technician JWT>"

# 1. View own profile
curl http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer $TECH_TOKEN"
# Expected: 200 with technician's profile

# 2. Update display name
curl -X PATCH http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"display_name": "Carlos Actualizado"}'
# Expected: 200 with new display_name

# 3. Change password — wrong current password
curl -X PATCH http://localhost:8000/api/v1/users/me/password \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"current_password": "wrong", "new_password": "newpass123"}'
# Expected: 400

# 4. Change password — too short
curl -X PATCH http://localhost:8000/api/v1/users/me/password \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"current_password": "COLBO2026", "new_password": "abc"}'
# Expected: 422

# 5. Change password — success
curl -X PATCH http://localhost:8000/api/v1/users/me/password \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"current_password": "COLBO2026", "new_password": "NewPass2026"}'
# Expected: 204

# 6. Old password no longer works
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "carlos.rios", "password": "COLBO2026"}'
# Expected: 401

# 7. New password works
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "carlos.rios", "password": "NewPass2026"}'
# Expected: 200

# 8. Technician cannot access supervisor routes
curl http://localhost:8000/api/v1/technicians \
  -H "Authorization: Bearer $TECH_TOKEN"
# Expected: 403
```

### Mobile validation

1. Log in as Technician → tap profile icon → profile screen shows display name and
   username (username field read-only).
2. Update display name → save → name updates throughout the app.
3. Tap "Change Password" → enter wrong current password → error shown.
4. Enter correct current password + new password < 6 chars → validation error shown.
5. Enter correct current password + valid new password → success → log out → log in
   with new password → access granted.
6. Attempt to navigate to technician-list route directly → redirected to home or
   access-denied screen.

---

## Contract References

- Auth endpoints: [`contracts/auth.yaml`](contracts/auth.yaml)
- User management endpoints: [`contracts/users.yaml`](contracts/users.yaml)
- Data model: [`data-model.md`](data-model.md)
