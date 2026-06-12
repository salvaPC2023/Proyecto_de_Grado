# Feature Specification: User Management Module

**Feature Branch**: `001-user-management`

**Created**: 2026-06-08

**Status**: Draft

**Input**: User description: "User management module for a mobile maintenance app. Two roles exist: Supervisor and Technician. The Supervisor account is pre-loaded in the system. Supervisors can create technician accounts (with a default password COLBO2026), edit technician profile data, and disable technician accounts. Supervisors can also view a list of all technicians. Technicians can log in, view their own profile, and edit their own profile data (name, password) without a profile picture. Both roles can log out."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Authentication & Session Management (Priority: P1)

Technicians and Supervisors authenticate with their username and password to access the
mobile app. The session persists between app opens so users do not need to re-login every
time. Both roles can log out to end their session securely.

**Why this priority**: All other features require an authenticated user. Without login,
the app is inaccessible. This story is the foundational gate for every other module.

**Independent Test**: Can be fully tested by logging in with the pre-loaded Supervisor
account, verifying access to the home screen, closing and reopening the app to confirm
session persistence, and then logging out.

**Acceptance Scenarios**:

1. **Given** a Supervisor with valid credentials, **When** they enter username and
   password, **Then** they are granted access to the Supervisor home screen.
2. **Given** a Technician with valid credentials, **When** they enter username and
   password, **Then** they are granted access to the Technician home screen.
3. **Given** any user with an incorrect password, **When** they submit login, **Then**
   they see a clear error message and are not granted access.
4. **Given** a disabled Technician account, **When** the technician attempts to log in,
   **Then** they are denied access with a message indicating the account is inactive.
5. **Given** an authenticated user, **When** they close and reopen the app, **Then**
   they remain logged in without re-entering credentials.
6. **Given** an authenticated user, **When** they tap Logout, **Then** their session is
   cleared and the app returns to the login screen.

---

### User Story 2 - Supervisor Creates Technician Account (Priority: P2)

A Supervisor creates a new technician account by providing profile information. The system
assigns the default password COLBO2026. The technician can immediately log in with these
credentials.

**Why this priority**: Technician accounts must exist before any operational feature
(work order assignment, field work) can proceed. This story enables the technician roster.

**Independent Test**: Can be fully tested by creating a new technician account as a
Supervisor, then logging in with the new credentials and the default password.

**Acceptance Scenarios**:

1. **Given** a Supervisor on the create-technician screen, **When** they fill in all
   required fields and confirm, **Then** a new Technician account is created with the
   default password COLBO2026 and status Active.
2. **Given** a newly created Technician account, **When** the technician logs in using
   the default password, **Then** access is granted.
3. **Given** a Supervisor creating an account, **When** they omit a required field,
   **Then** a validation error is shown and the account is not created.
4. **Given** a Supervisor creating an account, **When** they enter a username already in
   use, **Then** an error is shown and the account is not created.

---

### User Story 3 - Supervisor Manages Technician Roster (Priority: P3)

A Supervisor can view the full list of all Technician accounts, navigate to an individual
technician's profile, edit their profile data, and disable or re-enable their account.
Disabled technicians are blocked from logging in and any active session is invalidated.

**Why this priority**: Roster management is essential for keeping the technician list
accurate and handling account lifecycle events such as new hires, data corrections, and
departures.

**Independent Test**: Can be fully tested by viewing the technician list, editing one
technician's name, disabling one account and verifying that the technician cannot log in,
then re-enabling the account and verifying login is restored.

**Acceptance Scenarios**:

1. **Given** a Supervisor on the technician list screen, **When** the screen loads,
   **Then** all Technician accounts are displayed with their name and status
   (Active / Disabled).
2. **Given** a Supervisor viewing a technician's profile, **When** they edit a profile
   field and save, **Then** the updated data is reflected immediately in the list and
   profile view.
3. **Given** a Supervisor on a technician's profile, **When** they disable the account
   and confirm, **Then** the account is marked Disabled and the technician cannot log in.
4. **Given** an active session belonging to a Technician whose account is then disabled,
   **When** the Supervisor confirms the disable action, **Then** the Technician's session
   is invalidated and the app returns them to the login screen.
5. **Given** a Supervisor on a Disabled technician's profile, **When** they re-enable
   the account, **Then** the Technician can log in again.
6. **Given** a Supervisor, **When** they attempt to disable a Supervisor account,
   **Then** the action is blocked with an appropriate message.
7. **Given** a Supervisor on a Technician's profile that has no assigned work orders,
   **When** they permanently delete the account and confirm, **Then** the account is
   removed from the system and no longer appears in the technician list.
8. **Given** a Supervisor attempting to delete a Technician account that has one or more
   assigned work orders, **When** they confirm the action, **Then** the deletion is
   rejected with a message indicating the account has linked work orders.
9. **Given** a Supervisor, **When** they attempt to delete a Supervisor account, **Then**
   the action is blocked with an appropriate message.

---

### User Story 4 - Self-Service Profile Management (Priority: P4)

Supervisors and Technicians can view their own profile and update their display name and
password. No profile picture is supported. A Technician cannot view or modify other
users' profiles.

**Why this priority**: Changing the default password is basic security hygiene for new
technician accounts. Profile self-management reduces Supervisor workload for routine data
corrections.

**Independent Test**: Can be tested by logging in as a Technician, updating the display
name, verifying the change persists after re-login, changing the password, and verifying
the new password is required for subsequent login.

**Acceptance Scenarios**:

1. **Given** any authenticated user, **When** they navigate to their profile screen,
   **Then** they see their display name and username (username is read-only).
2. **Given** any authenticated user, **When** they update their display name and save,
   **Then** the new name is persisted and displayed throughout the app.
3. **Given** any authenticated user, **When** they submit a password change with the
   correct current password, **Then** the new password is set and required for the next
   login.
4. **Given** any authenticated user, **When** they enter an incorrect current password
   during a password change, **Then** the change is rejected with an appropriate error.
5. **Given** any authenticated user, **When** they submit a new password shorter than
   6 characters, **Then** the change is rejected with a validation message.
6. **Given** a Technician, **When** they attempt to navigate to the technician list or
   any account-management screen, **Then** access is blocked.

---

### Edge Cases

- What happens when a disabled Technician's session is still active (already logged in)?
  The session MUST be invalidated immediately upon the Supervisor confirming the disable
  action.
- What happens if the Supervisor tries to access the technician-management screens from a
  Technician-role account? Access is blocked — role checks are enforced on both client
  and server.
- What happens when two Supervisors simultaneously edit the same Technician record?
  Last-write-wins with a success confirmation; no optimistic-lock error is required in
  this version.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a login screen where users enter username and password.
- **FR-002**: System MUST persist the user's session across app restarts until the user
  explicitly logs out.
- **FR-003**: System MUST deny login to disabled accounts with a clear, user-facing
  message.
- **FR-004**: Supervisors MUST be able to create Technician accounts; the system MUST
  assign the password COLBO2026 automatically at creation.
- **FR-005**: Supervisors MUST be able to view a list of all Technician accounts showing
  name and status (Active / Disabled).
- **FR-006**: Supervisors MUST be able to edit a Technician's display name and username.
- **FR-007**: Supervisors MUST be able to disable and re-enable Technician accounts.
- **FR-008**: Disabling a Technician account MUST immediately invalidate any active
  session held by that account.
- **FR-009**: Both roles MUST be able to view their own profile (display name, username).
- **FR-010**: Both roles MUST be able to update their own display name.
- **FR-011**: Both roles MUST be able to change their own password, with current password
  required as confirmation.
- **FR-012**: New passwords MUST be at least 6 characters long.
- **FR-013**: Both roles MUST be able to log out, clearing their local session.
- **FR-014**: Supervisors MUST NOT be able to disable Supervisor accounts through this
  module.
- **FR-015**: Username MUST be unique across all accounts in the system.
- **FR-016**: Technicians MUST NOT be able to access Supervisor-only screens or perform
  account-management actions.
- **FR-017**: Supervisors MUST be able to permanently delete a Technician account that
  has no assigned work orders.
- **FR-018**: System MUST reject deletion of a Technician account that has one or more
  assigned work orders, returning a clear error message.
- **FR-019**: Supervisors MUST NOT be able to delete Supervisor accounts.

### Key Entities

- **User Account**: Represents an authenticated system user. Attributes: username
  (unique, login identifier), display name, role (Supervisor | Technician), status
  (Active | Disabled).
- **Session**: Represents an active authenticated context for a user. Invalidated on
  logout or when the associated account is disabled.
- **Role**: Enumerated value (Supervisor | Technician) that governs accessible screens
  and permitted actions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A Supervisor can create a new Technician account and the technician can log
  in for the first time within 2 minutes end-to-end.
- **SC-002**: The Supervisor technician-list loads all accounts within 3 seconds for a
  roster of up to 200 technicians.
- **SC-003**: Disabling a Technician account takes effect within 5 seconds of the
  Supervisor confirming the action — the account cannot authenticate or continue an
  active session after that window.
- **SC-004**: 100% of app screens beyond the login screen are inaccessible without a
  valid, active session.
- **SC-005**: 100% of Supervisor-only screens return an access-denied response when
  reached by a Technician-role session.

## Assumptions

- The Supervisor account is seeded at system initialization; no self-registration flow
  exists.
- Only one Supervisor account exists in the initial version; multi-supervisor support is
  out of scope.
- Technician profile fields for both creation and Supervisor-edit are: display name and
  username. Additional fields (phone, employee ID, etc.) are out of scope for this
  feature.
- The default password COLBO2026 is intentional and static. Forced password change on
  first login is not required in this iteration.
- Username is set at account creation and can be edited by the Supervisor afterward;
  Technicians cannot change their own username.
- No email address is collected or required in this version.
- Profile pictures are explicitly out of scope for all roles.
- The app requires an active internet connection for all actions in this module; offline
  authentication is out of scope.
