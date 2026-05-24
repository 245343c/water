# Backend migration status

**Mode:** `useBackend = true` only (see `lib/core/services/api/api_config.dart`).

**Stack:** Flutter → Express API → MongoDB (not Firebase).

Last updated: Phase A (repo hygiene + docs).

---

## Phase A completed

| Item | Status |
|------|--------|
| `.gitignore` for `backend/node_modules`, `.env`, `uploads` | Done |
| Remove `node_modules` from git tracking | Done |
| Delete `lib/data/mock/*` | Done |
| Remove dead local notification insert methods | Done |
| Env-based API URL (`--dart-define=API_BASE_URL=...`) | Done |
| Fix `api_config.dart` import | Done |
| Update README + this doc | Done |

---

## Wired to API (production paths)

| Area | APIs |
|------|------|
| Auth | login, register, OTP, forgot/reset password, driver account, `/auth/me` |
| Shop | GET/PUT shop, listed shops |
| Customers | CRUD, linked customers, delivery profile |
| Drivers | list, create, active toggle, driver login account |
| Products | list, create, update, delete, image upload |
| Orders | place, accept, reject, assign, driver-accept, status, customer edit/cancel |
| Deliveries | list, create |
| Cash | list, record payment |
| Bills | list (admin refresh), reports dashboard/monthly/pending |
| Notifications | list, mark read (server creates on events) |

---

## Intentional dev / not production yet

| Area | Notes |
|------|--------|
| Customer OTP | OTP in JSON in dev; `CUSTOMER_DEMO_OTP` in backend `.env` |
| Forgot-password OTP | OTP in response in dev |
| Login demo hints | On staff login screens — remove for release |
| Local push | Device banners only — no FCM |
| Subscription screen | UI mock — no Razorpay |
| Mark all notifications read | Local UI only — no bulk API |

---

## Next phases (see [PENDING_WORK.md](PENDING_WORK.md))

- **Phase B:** Order pricing, delivery→order `delivered`, customer bills API, etc.
- **Phase C:** Promotions admin, block customer, edit/delete delivery & payment
- **Phase D:** SMS, cloud uploads, FCM, subscription, CI, deploy

---

## How to run

1. MongoDB + `cd backend && npm install && npm run dev`
2. `npm run seed`
3. `flutter pub get && flutter run`
4. Smoke test: `cd backend && npm run test:smoke` (server running)
