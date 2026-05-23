# Backend-only migration status

**Mode:** `useBackend = true` only (see `lib/core/services/api/api_config.dart`).

Last updated: production-readiness pass.

---

## Intentionally kept as dev/mock (you approved)

| Area | What happens | Production follow-up |
|------|----------------|----------------------|
| Customer OTP | API returns OTP in JSON in dev; fixed `123456` when `NODE_ENV !== production` | SMS provider (MSG91, Twilio, Firebase Phone) |
| Staff forgot-password OTP | OTP in API response + in-memory store | Email/SMS delivery, Redis for OTP |
| In-app notifications | Created in Flutter memory on order/delivery events; `loadFromBackend` reads DB | Call `POST /api/notifications` from app or server hooks on order/delivery |
| Local push banners | `PushNotificationService` — device notifications only | FCM |
| Subscription screen | UI mock actions, no Razorpay | Billing integration |
| Login demo hints | Admin/driver credentials on login screen | Remove in production builds |

---

## Removed in this pass

- In-memory mock data seed (`_seedMockData`, `lib/data/mock/*` no longer loaded at runtime)
- **Reset mock data** menu (More screen)
- Offline `useBackend = false` auth paths (throw `UnsupportedError`; use `*Async` methods)
- Google customer login (`loginWithGoogle` / `/auth/customer/google` unused by UI)
- Mock driver login detection via `_accounts` (`hasAccountForDriver` → use `driverHasLoginAccount` + driver `uid` from API)

---

## Wired to real API in this pass

| Feature | API |
|---------|-----|
| Customer delivery profile | `PATCH /api/customers/me/delivery-profile` |
| Customer linked CRM rows | `GET /api/customers/me/linked` |
| User onboarding flag | `PATCH /api/auth/me` |
| Driver start delivery | `PATCH /api/orders/:id/status` (`out_for_delivery`) |
| Order status from server | Full mapping in `_orderFromJson` (incl. cancelled, out for delivery) |
| Driver route list | All shop customers from API (not mock route IDs) |
| Customer `appUserId`, lat/lng on CRM | Parsed from MongoDB |

---

## Still pending (real work later)

| Priority | Item |
|----------|------|
| High | Persist notifications via API when orders/deliveries change |
| High | Product image upload to server storage |
| High | Admin profile photo upload |
| Medium | Monthly bills: use `/api/bills` instead of client-only math |
| Medium | Reports: use `/api/reports/*` |
| Medium | Promotions admin CRUD in UI |
| Medium | `assignDriver` on orders from admin UI |
| Medium | Product edit (`PUT /api/products/:id`) in UI |
| Low | Driver “Accept delivery” timestamp on server (currently local until refresh) |
| Low | Route notes / curated daily route (needs backend model) |
| Low | Delete or archive `lib/data/mock/` files |
| Low | Rewrite `test/widget_test.dart` as integration tests |

---

## How to run (backend-only)

1. MongoDB + `cd backend && npm run dev`
2. `node scripts/seed.js` (admin, driver, demo customer `9999999999`, OTP `123456`)
3. Flutter with `useBackend = true` (default)
4. Customer login: phone registered in CRM → OTP from API response in dev
