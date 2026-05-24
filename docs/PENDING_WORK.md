# Pending work — Sri Sai RO Water

**Living checklist** from a full repo audit (code, backend routes, Flutter wiring, docs, git).

**Last updated:** 2026-05-24  
**Branch reviewed:** `backend-foundation-local`  
**Mode:** `useBackend = true` — MongoDB + Express API (not in-app mock data)

---

## Executive summary

| Area | Status |
|------|--------|
| Core business (customers, deliveries, payments, products, orders, drivers) | **Mostly live** |
| Auth (admin/driver email, customer OTP) | **Live** |
| Reports / bills | **Partially live** |
| Production readiness | **Not ready** — dev shortcuts, missing features, doc drift, repo hygiene |

**Legend:** ✅ Done · ⚠️ Partial · ❌ Not done

---

## CRITICAL — fix before real users / production

| # | Item | Detail |
|---|------|--------|
| C1 | ~~**`backend/node_modules` in git**~~ | ✅ Phase A — untracked + `.gitignore` |
| C2 | ~~**`.gitignore` gaps**~~ | ✅ Phase A |
| C3 | ~~**Root `README.md` outdated**~~ | ✅ Phase A |
| C4 | **`docs/BACKEND_MIGRATION_STATUS.md` outdated** | Lists as pending items already done (uploads, assign driver, edit product, reports/bills). |
| C5 | **Master plan / architecture docs drift** | `MASTER_PLAN.md` / `PRODUCT_ARCHITECTURE.md` still describe Firebase + mock-first; stack is MongoDB + Express. |
| C6 | **Order not marked `delivered` in DB** | Delivery recording does not link `orderId` or call `PATCH /orders/:id/status` with `delivered`. Customer “delivered” UI often inferred from delivery list in memory. |
| C7 | **Order pricing on place order** | `POST /api/orders` saves qty only; `subtotal`, `totalAmount`, `items[]` not computed server-side from shop prices. |
| C8 | **Physical device API URL** | `api_config.dart` uses `localhost` / `10.0.2.2` only. Real USB phone needs PC LAN IP or env-based URL. |
| C9 | **OTP / password reset not production-safe** | Dev returns OTP in API JSON; SMS/email not integrated. Demo OTP shown on login screens. |
| C10 | **Image storage local only** | `POST /api/uploads/image` → `backend/uploads/` on disk. Needs cloud storage + `PUBLIC_BASE_URL` in prod. |

---

## HIGH — backend exists, app missing or partial

### Admin — API exists, no UI / not wired

| Feature | Backend endpoint | Flutter gap |
|---------|------------------|-------------|
| Block customer | `PATCH /api/customers/:id/block` | No UI; customer status not shown in app |
| Edit driver | `PUT /api/drivers/:id` | Add + active toggle only |
| Delete driver | `DELETE /api/drivers/:id` | Not wired |
| Edit delivery | `PUT /api/deliveries/:id` | Delivery history read-only |
| Delete delivery | `DELETE /api/deliveries/:id` | Not wired |
| Edit payment | `PUT /api/cash/:id` | Payment history read-only |
| Delete payment | `DELETE /api/cash/:id` | Not wired |
| Soft-disable product | `PATCH /api/products/:id/active` | Hard delete only in UI |
| Generate monthly bill | `POST /api/bills/generate` | Client-side bill math instead |
| Update bill status | `PATCH /api/bills/:id/status` | Not wired |
| Daily report | `GET /api/reports/daily` | Not used |
| Promotions admin CRUD | `POST/PUT/PATCH/DELETE /api/promotions` | No admin screen; customer read-only |
| Manual notification | `POST /api/notifications` | Server auto-creates on events only |
| Delete notification | `DELETE /api/notifications/:id` | Not wired |

### Customer — API exists, not wired

| Feature | Backend | Flutter gap |
|---------|---------|-------------|
| My bills API | `GET /api/bills/customer/mine` | Uses `monthlyStatsForCustomer()` from loaded deliveries |
| Google login | `POST /api/auth/customer/google` | No Flutter integration |
| Public shop | `GET /api/shop/public/:shopId` | Uses cached `repo.shopById` only |

### Driver — API exists, not wired

| Feature | Backend | Flutter gap |
|---------|---------|-------------|
| Driver profile | `GET /api/drivers/me/profile` | Uses admin-loaded driver list |
| Availability | `PATCH /api/drivers/me/availability` | Not wired |
| Mark delivered | `PATCH /api/orders/:id/status` (`delivered`) | Never called |

### Notifications

| Issue | Detail |
|-------|--------|
| Mark all read | Local-only in `NotificationRepository`; no bulk API |
| Dead code | `recordDelivery`, `notifyAdminOrderPlaced`, etc. in `notification_repository.dart` — never called |
| FCM | `PushNotificationService` — local banners only; second banner simulates customer device |

### Other high gaps

| Item | Detail |
|------|--------|
| **`BillsScreen` not routed** | File exists + calls `refreshMonthlyBills`; not in `app_router.dart` or More menu |
| **Reports custom ranges** | API used only for single calendar month; week/custom ranges use client fallback |
| **Server search unused** | `GET /customers?q=`, `GET /shop/listed?q=`, `GET /notifications?unread=` — app filters locally |
| **Load limits** | Deliveries ~60 days / 200 rows; orders 100; cash 200 — busy shops may miss data |
| **28 `ApiDataService` methods never called** | See `lib/core/services/api/api_data_service.dart` vs repository usage |

---

## MEDIUM — mock / placeholder (replace before launch)

| Item | Location | Replace with |
|------|----------|--------------|
| Subscription / Razorpay | `lib/features/subscription/subscription_screen.dart` | Billing API + MongoDB shop subscription fields |
| Shop subscription enforcement | `Shop.isVisibleToCustomers` (Flutter); no fields on MongoDB `Shop` | Backend fields + enforce on listed shops API |
| Driver route notes | `_routeNotes` in `water_plant_repository.dart` — getter only, **no setter** | New API + collection |
| FCM push | `lib/core/services/push_notification_service.dart` | Firebase Cloud Messaging |
| Demo credentials on login | `login_screen_widgets.dart`, `auth_screen_widgets.dart` | Hide in release (`kReleaseMode`) |
| Demo OTP on screen | `customer_login_screen.dart`, `forgot_password_screen.dart` | Hide in release |
| JWT logout blacklist | Client clears token only | Optional refresh tokens / denylist |

---

## MEDIUM — code / repo hygiene

| Item | Location / action |
|------|-------------------|
| Delete dead mock files (8, zero imports) | `lib/data/mock/*.dart` |
| Dead methods | `_seedProducts`, `_linkCustomerToShop` in `water_plant_repository.dart` |
| Stale interface comments | `i_water_plant_repository.dart` references mock / `ApiWaterPlantRepository` |
| Unused auth field | `_pendingCustomerOtp` in `auth_repository.dart` |
| Widget tests | Only 1 trivial test; integration test skipped in `test/widget_test.dart` |
| No project CI | No `.github/workflows` in repo root |
| Backend unit tests | Only `backend/scripts/smoke-test.js` (+ `--load`) |
| Flutter analyzer warnings | ~10 warnings (unused imports, dead code) — cleanup recommended |

---

## LOW — documentation drift

| Document | Issue |
|----------|--------|
| `docs/CLOSED_SHOP_CUSTOMER_UI_PLAN.md` | Mock data plan section obsolete |
| `docs/MASTER_PLAN.md` | Demo phone `9876543210`; seed uses `9999999999` |
| `docs/PRODUCT_ARCHITECTURE.md` | Customer “(mock)”; offline queue not implemented |
| `docs/PRODUCT_ARCHITECTURE.md` | “Directions on cards” — planned, not done |

---

## DONE — do not re-implement

Verified wired to MongoDB API:

- Admin/driver email login; customer OTP login; shop admin register
- Customer CRUD (add/edit/delete)
- Add delivery → `deliveries` + pending balance
- Record payment → `cashcollections`
- Products add/edit/delete + image upload URL
- Orders: place, accept, reject, assign driver, driver accept, out for delivery
- Dashboard stats; reports (single-month); bills list refresh
- Notifications list + mark one read (server creates on order/delivery)
- Settings → `PUT /api/shop`; admin photo upload
- Drivers: add, create login, active toggle
- Promotions read (customer tab)
- Backend: Winston, rate limits, helmet, MongoDB pool

---

## Suggested phases

### Phase A — Stability & repo ✅ (completed 2026-05-24)

1. ~~Fix `.gitignore`; remove `backend/node_modules` from git~~  
2. ~~Update `README.md`, `BACKEND_MIGRATION_STATUS.md`, master/architecture docs~~  
3. ~~Delete `lib/data/mock/*` + dead notification methods~~  
4. ~~Env-based API base URL (`--dart-define=API_BASE_URL`)~~

### Phase B — Core business correctness (3–5 days)

5. Order pricing on place order (server)  
6. Link delivery → order → status `delivered`  
7. Wire `GET /api/bills/customer/mine`  
8. Wire `POST /api/bills/generate` or auto-generate month-end  
9. Mark-all-read notifications (bulk API or loop)  
10. Route `BillsScreen` in admin menu or remove file

### Phase C — Admin completeness (3–5 days)

11. Promotions admin CRUD UI  
12. Block customer UI  
13. Edit/delete delivery & payment (if required)  
14. Product soft-disable  
15. Driver edit / availability APIs in UI

### Phase D — Production (1–2 weeks)

16. SMS OTP; hide dev OTP in release  
17. Cloud image storage  
18. FCM push  
19. Subscription + Razorpay + shop fields in MongoDB  
20. Integration tests + CI  
21. Deploy (MongoDB Atlas, HTTPS API, secrets)

---

## Quick reference: live vs mock

```
LIVE (MongoDB)          MOCK / NOT DONE
────────────────────────────────────────────
Login                   Subscription page
Customers               Route notes (no save)
Deliveries              FCM push
Payments                Google customer login
Products                Promotions admin UI
Orders (partial)        Many admin edit/delete APIs
Notifications (read)    Mark-all-read sync
Reports (monthly)       Reports (custom ranges)
Bills (partial)         BillsScreen in navigation
Shop settings           Shop subscription in DB
Image upload URL        Cloud CDN
OTP (DB-backed)         SMS delivery
```

---

## Related docs

- [MASTER_PLAN.md](MASTER_PLAN.md) — product vision (needs update for MongoDB stack)
- [PRODUCT_ARCHITECTURE.md](PRODUCT_ARCHITECTURE.md) — roles & permissions
- [BACKEND_MIGRATION_STATUS.md](BACKEND_MIGRATION_STATUS.md) — migration log (needs refresh)
- [AGENTS.md](../AGENTS.md) — agent rules

---

*Update this file when items are completed or scope changes.*
