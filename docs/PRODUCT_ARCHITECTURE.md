# Sri Sai RO Water — Product Architecture

This document is the **source of truth** for roles, permissions, and UI scope. All new features must align with it.

## App model

**One Flutter app**, multiple **roles** after login:

| Role | Status | Shell |
|------|--------|--------|
| **Admin** | Implemented | Dashboard · Customers · Orders · Products · Menu |
| **Driver** | Implemented | Route · Customers · Profile |
| **Customer** | Implemented (mock) | Home · Orders · Profile — see [MASTER_PLAN.md](MASTER_PLAN.md) |

## Design system (premium)

- Font: **Poppins** (`google_fonts`)
- Admin/Customer headers: navy gradient `#001F3F` → `#002B5C`
- Driver accent: **teal** `#0D9488` / `#14B8A6` (field app feel)
- Cards: white, 14–16px radius, light border `#E5E7EB`, soft shadow
- Primary actions: `#1A73E8` (admin), teal gradient (driver)
- Reuse shared widgets: `CustomerInfoBar`, delivery flows, login premium scaffold

## Permissions matrix

| Capability | Admin | Driver | Customer (future) |
|------------|:-----:|:------:|:-----------------:|
| Dashboard / reports | ✓ | — | — |
| Manage products & settings | ✓ | — | — |
| Manage drivers | ✓ | — | — |
| Add/edit/delete customers | ✓ | — | — |
| View customers | ✓ | ✓ | own only |
| View orders | ✓ | ✓ | own only |
| Accept/reject orders | ✓ | — | create |
| Record delivery / cans | ✓ | ✓ (field UI on customer) | — |
| Delivery notifications | receives | — | receives (in-app store; push mock) |
| Record payments | ✓ | — | view own |
| Monthly bills / ledger | ✓ | — | limited |

Enforce in **three layers**: `AppPermissions` → **go_router redirect** → **hide UI actions**.

## Driver rules

- Login: email + password (created by admin).
- **Field flow:** visit customer → ask how many cans → enter normal/cool on customer screen → **Save & notify** → admin + customer notified (in-app + local push mock).
- Home: **Route** — admin-confirmed customer requests + today's stops + completed.
- Driver sees **accepted orders only** (not pending). Admin accept → push + in-app alert to driver.
- **Customers**: search/list; detail is read-only except **Add delivery**.
- Cannot edit prices, payments, settings, or customer profile.
- Deliveries store optional `driverId` for audit.

## Admin: driver management

- Menu → **Drivers**: add name, phone, email, password; deactivate driver.
- Credentials are shared with driver manually (SMS/WhatsApp); no plain-text storage in UI after create.

## Routing

- Admin home: `/`
- Driver home: `/driver/route` (legacy `/driver/today` redirects)
- Driver customer: `/driver/customers/:id`
- Shared delivery flow: `/customers/:id/delivery` (allowed for driver with guard)

## Phases

1. **Now**: Roles, driver shell, admin drivers (mock auth).
2. **Next**: Backend JWT with role claims, sync, offline queue.
3. **Later**: Customer role + OTP login.

## Code map

- `lib/core/auth/` — roles, permissions, home routes
- `lib/features/driver/` — driver UI
- `lib/features/admin/` — drivers management
- `lib/routing/app_router.dart` — guards
