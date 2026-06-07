# Sri Sai RO Water — Product Architecture

This document is the **source of truth** for roles, permissions, and UI scope. All new features must align with it.

## App model

**One Flutter app**, multiple **roles** after login:

**Current release scope:** admin + driver only. Customer portal UI is paused and must not be exposed through app entry or routing.

| Role | Status | Shell |
|------|--------|--------|
| **Admin** | Implemented | Dashboard · Customers · Orders · Products · Menu |
| **Driver** | Implemented | Customers · Deliveries · Profile |
| **Customer** | Implemented (mock) | Home · Orders · Profile — see [MASTER_PLAN.md](MASTER_PLAN.md) |

Current release app entry opens directly to staff sign-in. The old `/welcome`
role picker is kept only as a legacy redirect to `/login`.

## Design system (premium)

- Font: **Poppins** (`google_fonts`)
- Admin/Customer headers: navy gradient `#001F3F` → `#002B5C`
- Driver accent: **teal** `#0D9488` / `#14B8A6` (field app feel)
- Cards: white, 14–16px radius, light border `#E5E7EB`, soft shadow
- Primary actions: `#1A73E8` (admin), teal gradient (driver)
- Reuse shared widgets: `CustomerInfoBar`, delivery flows, login premium scaffold

## Language support

- Supported app languages: English, Telugu, Hindi.
- UI translations live in the Flutter app; Firebase stores only `languageCode`
  on the user profile.
- Firestore status keys and business data remain stable and untranslated
  (`accepted`, `delivered`, official customer names, official addresses,
  product names, etc.).
- Customers can optionally store driver-only display fields such as
  `driverNameTe`, `driverNameHi`, `driverAddressNoteTe`, and
  `driverAddressNoteHi`. Driver UI shows these fields when the driver's
  selected language matches; admin, billing, and reports keep using official
  customer data.
- Drivers and admins can choose their own language. Admin-created driver
  credentials do not force the driver's language.

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

## Customer model

- Customers are monthly customers created by admins.
- There is no separate on-demand customer type in the current scope.
- Customers can request/order water from the customer app.
- Requests are attached to the existing monthly customer record for the selected plant.
- Multiple admins/plants can add the same customer phone number. The customer app shows every linked plant for that phone.

## Driver rules

- Login: mobile number + password (created by admin). Admin login still uses email + password.
- **Field flow:** visit customer → ask how many cans → enter normal/cool on customer screen → **Save & notify** → admin + customer notified (in-app + local push mock).
- Home: **Customers** — driver searches/selects a customer first; Deliveries shows admin-confirmed requests + today's stops + completed.
- Driver sees **accepted orders only** (not pending). Admin accept → push + in-app alert to driver.
- **Customers**: search/list; detail is read-only except **Add delivery**.
- Cannot edit prices, payments, settings, or customer profile.
- Deliveries store optional `driverId` for audit.

## Admin: driver management

- Menu → **Drivers**: add name, phone, optional contact email, password; deactivate driver.
- Credentials are shared with driver manually (SMS/WhatsApp): mobile number + password. No plain-text storage in UI after create.

## Routing

- Staff sign-in: `/login`
- Admin home: `/`
- Driver home: `/driver/customers` (legacy `/driver/today` redirects)
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
