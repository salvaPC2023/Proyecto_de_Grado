# Quickstart Validation Guide: LLM Description Standardization Module

**Feature**: `003-llm-description-standardization` | **Date**: 2026-06-12

This guide covers runnable validation scenarios that prove the feature works end-to-end.
For API schema details see [contracts/standardize.yaml](contracts/standardize.yaml).
For entity definitions see [data-model.md](data-model.md).

---

## Prerequisites

- Feature 002 fully deployed: the PM01 closure form exists and a valid Technician JWT can be
  obtained by logging in
- `ANTHROPIC_API_KEY` environment variable set on the Railway backend instance
- Mobile app rebuilt with the `standardization_panel.dart` widget integrated into the PM01
  closure form screen

---

## Scenario 1 — Happy Path: Standardization Returns and Is Confirmed

**Goal**: Verify that a Technician can standardize a free-text description, review the result,
and submit the closure with the confirmed text stored.

**Setup**:
1. Log in as a Technician
2. Open an assigned OT that has at least one PM01 step in `released` status

**Steps**:
1. Open the PM01 step closure form
2. Enter a free-text work description (e.g., *"cambie el rodamiento del eje 2 estaba desgastado"*)
3. Verify the "Standardize description" button is visible and enabled (device is online, field
   is non-empty)
4. Tap "Standardize description"
5. Verify a loading indicator appears on or near the button
6. Wait for the result (≤ 10 seconds per SC-001)
7. Verify a standardization panel appears showing:
   - The normalized text in an editable field
   - A "Confirm" action
   - A "Keep original" action
8. (Optional) Edit the normalized text
9. Tap "Confirm"
10. Verify the panel closes and the work description field now contains the confirmed text
11. Submit the closure form
12. Log in as the Supervisor and open the OT detail
13. Verify the PM01 step closure shows the confirmed (standardized or edited) description

**Expected outcome**: The text stored in the `work_description` column matches exactly what the
Technician confirmed in step 9 — no original text retained.

---

## Scenario 2 — Keep Original: Technician Discards the Standardized Version

**Goal**: Verify that "Keep original" restores the original text with no side effects.

**Setup**: Same as Scenario 1, step 1–7

**Steps**:
1. Follow Scenario 1, steps 1–7 (standardization panel visible with normalized text)
2. Tap "Keep original"
3. Verify the standardization panel closes
4. Verify the work description field contains the original text entered in step 2 of Scenario 1
5. Verify no changes were applied to the form
6. Submit the closure normally

**Expected outcome**: The original text is stored as-is; the normalized text is discarded.

---

## Scenario 3 — Re-standardize After Editing Description

**Goal**: Verify that a second standardization request uses the updated text.

**Steps**:
1. Open the PM01 closure form and enter a short description
2. Tap "Standardize description" — receive a result — tap "Keep original" to dismiss
3. Edit the work description field to a different longer text
4. Tap "Standardize description" again
5. Verify the new standardization request is sent and the new result reflects the updated text

**Expected outcome**: A fresh request is issued; the panel shows a normalized version of the
new text, not the first text.

---

## Scenario 4 — Service Unavailable (Backend Returns 503)

**Goal**: Verify the non-blocking fallback when the LLM service is unavailable.

**Setup**: Temporarily set `ANTHROPIC_API_KEY` to an invalid value on Railway, or use a test
double that returns 503 in the backend.

**Steps**:
1. Open the PM01 closure form and enter a description
2. Tap "Standardize description"
3. Verify a loading indicator appears briefly
4. Verify a non-blocking error message appears (e.g., *"Standardization unavailable. You can
   submit your original description."*) within 10 seconds
5. Verify the work description field still contains the original text
6. Verify the Technician can tap "Retry" to send a new request
7. Verify the Technician can dismiss the error and submit the closure without any extra steps

**Expected outcome**: Closure form remains fully functional; original text is preserved;
no extra confirmation or warning blocks submission.

---

## Scenario 5 — Timeout (LLM Exceeds 8 s)

**Goal**: Verify that a slow LLM call returns a 504 and the mobile shows the fallback.

**Setup**: Use a test double that delays the LLM response beyond 8 seconds.

**Steps**:
1. Follow steps 1–4 of Scenario 4 (but wait for the timeout response — within 10 s total)
2. Verify a 504 response triggers the same non-blocking error UI as Scenario 4

**Expected outcome**: Mobile shows the timeout error message; original text preserved;
closure submission not blocked.

---

## Scenario 6 — Offline: Button Hidden, Form Functional

**Goal**: Verify that the standardization button is absent when the device is offline.

**Steps**:
1. Enable Airplane Mode on the test device
2. Open the PM01 closure form (it may use cached data from Feature 002)
3. Enter a work description
4. Verify the "Standardize description" button is hidden or visibly disabled
5. Verify the rest of the closure form is fully functional
6. Submit the closure (it will be queued by the Feature 002 offline queue mechanism)

**Expected outcome**: No standardization attempted; closure queued normally; original
text preserved in the queue.

---

## Scenario 7 — Empty Description: Button Disabled

**Goal**: Verify the button is disabled until the Technician enters text.

**Steps**:
1. Open the PM01 closure form (device online)
2. Leave the work description field empty
3. Verify the "Standardize description" button is disabled or grayed out
4. Enter one character
5. Verify the button becomes enabled

**Expected outcome**: Button enable/disable state is gated on field content.

---

## API Smoke Test (curl)

Run against the Railway backend URL with a valid Technician JWT:

```bash
# Obtain a token first (Feature 002 login endpoint)
TOKEN=$(curl -s -X POST https://<host>/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"tech01","password":"COLBO2026"}' | jq -r '.access_token')

# Standardize a description
curl -s -X POST https://<host>/api/v1/descriptions/standardize \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text": "cambie el rodamiento del eje 2 estaba muy desgastado y hacia ruido"}' \
  | jq .
```

**Expected response (200)**:
```json
{
  "standardized_text": "Acción: Reemplazo de rodamiento\nComponente: Eje 2\nHallazgo: Rodamiento con desgaste avanzado y generación de ruido anormal\nResultado: Eje 2 operativo tras sustitución del rodamiento"
}
```

**Test 400 (empty text)**:
```bash
curl -s -X POST https://<host>/api/v1/descriptions/standardize \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text": ""}' | jq .
# Expected: { "detail": "El campo 'text' no puede estar vacío." }
```

**Test 401 (no token)**:
```bash
curl -s -X POST https://<host>/api/v1/descriptions/standardize \
  -H "Content-Type: application/json" \
  -d '{"text": "test"}' | jq .
# Expected: { "detail": "No autenticado." }
```
