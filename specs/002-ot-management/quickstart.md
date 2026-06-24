# Quickstart & Validation Guide: OT Management Module

**Feature**: `002-ot-management` | **Date**: 2026-06-08

This guide describes how to validate that each user story works end-to-end after
implementation. It is a run/test guide, not an implementation reference.

## Prerequisites

- Feature 001 (User Management) fully implemented and verified
- Backend running (Railway or local) with PostgreSQL connected and migrations applied
- At least one Technician account exists (created via feature 001 — see feature 001
  quickstart.md Story 2)
- Technical location data seeded (Alembic seed migration with at least 3 leaf nodes)
- Flutter app built and running on a simulator/device connected to the backend
- Environment variables set: `JWT_SECRET_KEY`, `DATABASE_URL`, `SERVER_TIMEZONE`
  (default `America/La_Paz`)
- HTTP client (curl, httpie, or Postman) for direct API testing

### Shared curl setup

```bash
# Login as Supervisor
SUPER_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "Admin2026"}' | jq -r '.access_token')

# Login as Technician (username from feature 001 Story 2)
TECH_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "carlos.rios", "password": "COLBO2026"}' | jq -r '.access_token')

# Get the technician's user ID
TECH_ID=$(curl -s http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer $TECH_TOKEN" | jq -r '.id')

# Get a technical location ID (first one in the list)
LOC_ID=$(curl -s http://localhost:8000/api/v1/technical-locations \
  -H "Authorization: Bearer $SUPER_TOKEN" | jq -r '.[0].id')
```

---

## Story 1 — Supervisor Creates Work Order (P1)

### Backend validation

```bash
# 1. Create a Work Order with one PM01 step
OT_RESPONSE=$(curl -s -X POST http://localhost:8000/api/v1/work-orders \
  -H "Authorization: Bearer $SUPER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"order_type\": \"OE01\",
    \"technical_location_id\": \"$LOC_ID\",
    \"assigned_technician_id\": \"$TECH_ID\",
    \"planner_group\": \"mechanical\",
    \"installation_state\": \"running\",
    \"planned_start\": \"2026-06-09\",
    \"planned_end\": \"2026-06-09\",
    \"priority\": 2,
    \"steps\": [
      {
        \"description\": \"Inspect motor bearings\",
        \"control_key\": \"PM01\",
        \"planned_intervention_time\": 2.5
      }
    ]
  }")
echo $OT_RESPONSE | jq .
OT_ID=$(echo $OT_RESPONSE | jq -r '.id')
# Expected: 201 with status=released, steps[0..2] are fixed PMNN, steps[3] is PM01
# Verify: steps array has 4 entries; first 3 have is_fixed=true, control_key=PMNN

# 2. Verify fixed steps are pre-populated
echo $OT_RESPONSE | jq '.steps[0,1,2] | {position, description, control_key, is_fixed}'
# Expected:
#   {position:1, description:"Piense de manera inteligente", control_key:"PMNN", is_fixed:true}
#   {position:2, description:"Vea, diga, haga algo", control_key:"PMNN", is_fixed:true}
#   {position:3, description:"Se tiene habilidades adecuadas para la tarea", control_key:"PMNN", is_fixed:true}

# 3. Attempt to create OT with no PM01 step (should fail)
curl -s -X POST http://localhost:8000/api/v1/work-orders \
  -H "Authorization: Bearer $SUPER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"order_type\": \"OE02\",
    \"technical_location_id\": \"$LOC_ID\",
    \"assigned_technician_id\": \"$TECH_ID\",
    \"planner_group\": \"electrical\",
    \"installation_state\": \"stopped\",
    \"planned_start\": \"2026-06-09\",
    \"planned_end\": \"2026-06-09\",
    \"priority\": 1,
    \"steps\": [
      {\"description\": \"Check insulation\", \"control_key\": \"PMNN\"}
    ]
  }"
# Expected: 400 with detail "At least one PM01 step is required."

# 4. Verify Technician cannot create OTs
curl -s -X POST http://localhost:8000/api/v1/work-orders \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"order_type":"OE01","priority":1,"steps":[]}'
# Expected: 403
```

### Mobile validation

1. Log in as Supervisor → navigate to "Create OT".
2. Fill all required fields: order type, technical location (drill-down selector navigates
   4 levels), assigned technician, planner group, installation state, planned dates, priority.
3. Observe that the step list is pre-populated with 3 read-only safety steps.
4. Add one custom PM01 step with description and planned time.
5. Submit → success toast; navigate back to shift list → OT appears with status Released.
6. Try to submit with no PM01 step → field-level error before submission.

---

## Story 2 — Technician Views Assigned Work Orders (P2)

### Backend validation

```bash
# 1. Technician lists their shift OTs
curl -s http://localhost:8000/api/v1/work-orders \
  -H "Authorization: Bearer $TECH_TOKEN" | jq .
# Expected: array containing the OT created in Story 1
# Verify: each item has order_type, technical_location, priority, planned_start,
#          planned_end, status, shift_number

# 2. Technician gets full OT detail
curl -s http://localhost:8000/api/v1/work-orders/$OT_ID \
  -H "Authorization: Bearer $TECH_TOKEN" | jq .
# Expected: full detail with all fields and steps array;
#            steps[0..2] is_fixed=true, steps[3] has closure=null

# 3. Supervisor list sees all shift OTs
curl -s http://localhost:8000/api/v1/work-orders \
  -H "Authorization: Bearer $SUPER_TOKEN" | jq '. | length'
# Expected: >= 1 (includes the OT assigned to carlos.rios)

# 4. Technician cannot access an OT assigned to another technician
# (Create a second technician via feature-001 first, then test)
# Expected: 403
```

### Mobile validation

1. Log in as Technician (carlos.rios) → shift OT list screen loads.
2. Verify the OT from Story 1 appears with correct summary fields (order type, location,
   priority, dates, status badge Released).
3. Tap the OT → detail view shows all fields; step list shows 4 steps.
4. Steps 1–3 are marked read-only (no action button); step 4 shows a "Register Closure"
   action.
5. All text fields display fully without truncation.

---

## Story 3 — Technician Registers PM01 Step Closure (P3)

### Backend validation

```bash
# Extract the PM01 step ID from the OT
STEP_ID=$(curl -s http://localhost:8000/api/v1/work-orders/$OT_ID \
  -H "Authorization: Bearer $TECH_TOKEN" | jq -r '.steps[] | select(.control_key=="PM01") | .id')

# 1. Submit a valid PM01 closure (online)
curl -s -X POST \
  "http://localhost:8000/api/v1/work-orders/$OT_ID/steps/$STEP_ID/closures" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "actual_duration": 1.5,
    "deviation_key": "PM01 Executed",
    "work_description": "Replaced worn bearing on shaft 2. Lubricated. Tested at full RPM for 10 minutes — no abnormal vibration.",
    "safety_question_response": false
  }' | jq .
# Expected: 201; returned WorkOrderDetail has status=notified,
#            notif_final=true, sin_ttbjo_real=true (only 1 PM01 step exists);
#            steps[3].closure is populated

# 2. Attempt duplicate closure (same step)
curl -s -X POST \
  "http://localhost:8000/api/v1/work-orders/$OT_ID/steps/$STEP_ID/closures" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"actual_duration":1.0,"deviation_key":"PM01 Executed","work_description":"Again","safety_question_response":false}'
# Expected: 409 Conflict

# 3. Test with missing field (validation error)
curl -s -X POST \
  "http://localhost:8000/api/v1/work-orders/$OT_ID/steps/$STEP_ID/closures" \
  -H "Authorization: Bearer $TECH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"actual_duration":1.0,"deviation_key":"PM01 Executed"}'
# Expected: 422 (missing work_description and safety_question_response)

# 4. Verify OT is now Notified
curl -s http://localhost:8000/api/v1/work-orders/$OT_ID \
  -H "Authorization: Bearer $TECH_TOKEN" | jq '{status, notif_final, sin_ttbjo_real}'
# Expected: {status:"notified", notif_final:true, sin_ttbjo_real:true}
```

### Offline validation

1. Disable WiFi/data on the device.
2. Tap "Register Closure" on a PM01 step → fill all 4 fields → submit.
3. Verify: success message shown with "pending sync" indicator on the step / OT card.
4. Re-enable WiFi → within 30 seconds the pending indicator clears; OT status updates
   to Notified (verify by refreshing the OT list).

### Mobile validation (online)

1. Tap "Register Closure" on the PM01 step → closure form opens with 4 fields.
2. Leave one field empty → tap Submit → field highlighted with validation message;
   form not submitted.
3. Fill all 4 fields → Submit → OT detail refreshes; PM01 step shows closure data;
   OT status badge changes to Notified.

---

## Story 4 — Supervisor Monitors Shift Work Orders (P4)

### Backend validation

```bash
# 1. Supervisor lists shift OTs — should include the Notified OT
curl -s http://localhost:8000/api/v1/work-orders \
  -H "Authorization: Bearer $SUPER_TOKEN" | jq '.[] | {id, status}'
# Expected: OT from Story 1 now has status=notified

# 2. Supervisor views Notified OT detail — checks work description
curl -s http://localhost:8000/api/v1/work-orders/$OT_ID \
  -H "Authorization: Bearer $SUPER_TOKEN" \
  | jq '.steps[] | select(.control_key=="PM01") | .closure | {work_description, safety_question_response}'
# Expected: full work_description (no truncation), safety_question_response=false
```

### Mobile validation

1. Log in as Supervisor → shift OT list shows the OT with status badge Notified.
2. Tap the OT → detail view; PM01 step shows the full work description text — no
   truncation (scroll if needed, full content readable).
3. Safety question response is displayed as an independent labelled field ("Equipo con
   riesgo: No" or similar).
4. Pull-to-refresh on the list updates status changes within one refresh.

---

## Story 5 — Supervisor Views Technical Location Report (P5)

### Backend validation

```bash
# 1. Get the report
curl -s http://localhost:8000/api/v1/technical-locations/report \
  -H "Authorization: Bearer $SUPER_TOKEN" | jq .
# Expected: array sorted descending by ot_count;
#            the technical location used in Story 1 has ot_count >= 1;
#            locations with 0 OTs also appear with ot_count=0

# 2. Technician cannot access the report
curl -s http://localhost:8000/api/v1/technical-locations/report \
  -H "Authorization: Bearer $TECH_TOKEN"
# Expected: 403

# 3. Create a second OT at the same location to verify count increments
#    (repeat Story 1 curl command with same LOC_ID, different technician or same)
#    Then re-fetch the report — ot_count for that location should be 2
```

### Mobile validation

1. Log in as Supervisor → navigate to Technical Location Report.
2. Verify list is sorted descending by OT count.
3. Create a new OT at the same location (Story 1 flow) → refresh the report → count
   increments by 1.
4. Verify a location with 0 OTs appears at the bottom with count 0.
5. Technician home screen has no navigation path to this report.

---

## Story 6 — Supervisor Views Technician Workload (P6)

### Backend validation

```bash
# 1. Get the workload summary for the current shift
curl -s http://localhost:8000/api/v1/work-orders/workload \
  -H "Authorization: Bearer $SUPER_TOKEN" | jq .
# Expected: array of objects; each has technician_id, technician_name, ot_count, shift_number
# The technician used in Story 1 (carlos.rios) should appear with ot_count >= 1
# Any technician with no OTs this shift appears with ot_count: 0
# All entries have the same shift_number (current shift)

# 2. Verify only the Supervisor's own technicians appear
# (Technicians created by a different Supervisor must NOT be in the response)
# If using a second Supervisor (e.g., gonzalo.orellana token), their workload
# endpoint should return their own technicians only, not carlos.rios.

# 3. Drill-down: get OTs for a specific technician
curl -s "http://localhost:8000/api/v1/work-orders?technician_id=$TECH_ID" \
  -H "Authorization: Bearer $SUPER_TOKEN" | jq .
# Expected: list of OTs assigned to carlos.rios for the current shift (same as US2/US4
# result filtered to this technician). Empty array if no OTs.

# 4. Technician cannot access the workload endpoint
curl -s http://localhost:8000/api/v1/work-orders/workload \
  -H "Authorization: Bearer $TECH_TOKEN"
# Expected: 403
```

### Mobile validation

1. Log in as Supervisor → navigate to "Technician Workload" screen.
2. Verify list shows all supervisor's technicians, each with their OT count badge.
3. Verify that a technician with no OTs still appears with count 0 (not hidden).
4. Tap a technician → drill-down screen shows only their OTs for the current shift with
   order type, technical location, and status for each.
5. Verify no create/edit actions are visible in the drill-down view.
6. Navigate back to the workload list → state is preserved or refetched cleanly.

---

## Contract References

- Work Orders: [`contracts/work-orders.yaml`](contracts/work-orders.yaml)
- Technical Locations: [`contracts/technical-locations.yaml`](contracts/technical-locations.yaml)
- Shifts: [`contracts/shifts.yaml`](contracts/shifts.yaml)
- Data Model: [`data-model.md`](data-model.md)
- Research Decisions: [`research.md`](research.md)
