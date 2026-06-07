# Sri Sai RO Water — Master Product & Technical Plan

**Version:** 1.0 · **Status:** Living document  
**App model:** One app on Play Store · Three roles · Firebase later (mock first)

**Current release scope:** ship admin + driver only. Customer portal UI and `/customer/*` routes are paused for this release.

---

## 1. Vision

A **water delivery platform** where:

- **Customers** sign in with an admin-created phone number, see only linked water plant(s), request water, and track account activity.
- **Shop owners (Admin)** manage customers, products, orders, monthly bills (contract customers), drivers, subscription.
- **Drivers** deliver and record cans at the doorstep.

**Revenue:** Shops pay **platform subscription** (30-day trial → paid listing). Customers use the app **free**.

---

## 2. One app — who sees what

For the current release, the app opens directly to Staff sign-in. The Order water/customer path remains paused.

| Entry on first screen | Role | Home after login |
|----------------------|------|------------------|
| **Order water** | Customer | Customer shell (Home · Orders · Profile) |
| **Staff login** | Admin | Dashboard · Customers · Orders · Products · Menu |
| **Staff login** | Driver | Customers · Deliveries · Profile |

**Play Store:** **1 app** — “Sri Sai RO Water” (or your brand name).

---

## 3. Design system (match admin — production premium)

All roles share:

| Token | Value | Usage |
|-------|--------|--------|
| Font | **Poppins** (Google Fonts) | All UI |
| Screen background | `#F3F4F6` | Lists |
| Card | White, radius 14–16, border `#E5E7EB`, soft shadow | Content |
| Admin/Driver/Customer headers | Navy gradient `#001F3F` → `#002B5C` | **Same as admin** |
| Primary button | `#1A73E8` | CTAs (customer + admin) |
| Driver accent | Teal `#0D9488` | Driver-only highlights |
| Customer accent | **Same primary blue** as admin | Familiar, one brand |
| Success | `#16A34A` | Delivered, paid |
| Warning | `#EA580C` | Pending order, trial ending |

**Customer UI matches admin:** same header gradient, cards, typography — feels like one professional product.

---

## 4. Customer model (closed network)

Customers are fixed admin-created monthly customers, not public marketplace users.

**Rules:**

- Admin creates every customer record.
- Customer app access is matched by the saved phone number.
- Customer sees only the shop(s) that added that phone number.
- Multiple admins/plants can add the same customer phone; the customer app then shows multiple linked plants.
- Customer app orders/requests are attached to the existing admin-created monthly customer record for the selected plant.
- The app must not create outside/public customers automatically.
- There is no separate on-demand customer type in the current scope.

---

## 5. Home delivery visibility (admin chooses at signup)

| `homeDeliveryAvailable` | Customer app |
|-------------------------|--------------|
| **Yes** | Shop listed · customers can order |
| **No** (pickup only) | **Hidden** from customer app entirely |

Set on **admin register** and editable in **Settings → Customer app**. Synced to `shops` collection in Firebase later.

---

## 6. Shop subscription (admin pays platform)

| Status | Customers see shop? | Admin app |
|--------|---------------------|-----------|
| `trial` (30 days) | Yes | Full access |
| `active` (paid) | Yes | Full access |
| `grace` (3–7 days) | Optional warning | Banner |
| `expired` | **Hidden** | Paywall to renew |

**Payment (later):** Razorpay subscription · mock “Activate plan” for now.

---

## 7. Order & delivery flow (end-to-end)

```text
CUSTOMER (fixed admin-created monthly customer)
  Sign in with linked phone -> Linked plant -> Request cans/products
        ↓
ADMIN
  Orders tab → Pending → Accept / Reject
        ↓ (on Accept)
DRIVER
  Push + Route “Customer requests” → Visit → Record cans → Save
        ↓
CUSTOMER + ADMIN
  Notifications · Order status updated
```

**Contract customers:** deliveries without app order → monthly bill at month-end (existing admin flow).

---

**Monthly customers:** direct deliveries and customer app requests both belong to the monthly account and appear in month-end billing.

## 8. Feature matrix (complete)

### 7.1 Customer app (in same APK)

| Feature | Phase (mock) | Firebase phase |
|---------|--------------|----------------|
| Welcome: Order water / Staff | ✓ | ✓ |
| Phone login (OTP mock) | ✓ | Auth phone |
| Onboarding: name, address, **map pin**, email optional | ✓ | Firestore profile |
| Home: nearby / featured active shops | ✓ (1 shop mock) | Geo query |
| Shop detail: products, prices, directions | ✓ | Firestore |
| Place order | ✓ | Cloud Function |
| My orders + status | ✓ | Firestore |
| Profile + delivery address edit | ✓ | Firestore |
| Favorites / multi-shop | Mock list | `userFavorites` |
| Promotions tab | Later | `promotions` |

### 7.2 Admin (existing + planned)

| Feature | Status |
|---------|--------|
| Dashboard, customers, products | Done |
| Orders accept/reject → notify driver | Done |
| Monthly bill PDF + WhatsApp | Done |
| Drivers management | Done |
| Subscription screen (trial/paywall) | Planned |
| Monthly customer account focus | Current scope |
| Shop registration / multi-shop | Planned |

### 7.3 Driver (existing)

| Feature | Status |
|---------|--------|
| Route, accepted orders only, field delivery | Done |
| Notifications on admin accept | Done |
| Directions on cards | Planned |

---

## 9. Firebase architecture (when you build backend)

### 8.1 Services

| Service | Use |
|---------|-----|
| **Firebase Auth** | Customer: phone OTP · Staff: email/password |
| **Cloud Firestore** | All data |
| **Cloud Storage** | Shop logos, promotion images, bill PDFs |
| **Cloud Functions** | Order created, accept → notify driver, subscription expiry |
| **FCM** | Push all roles |
| **Razorpay** (external) | Shop subscription webhooks → Functions |

### 8.2 Firestore collections (multi-tenant)

```text
users/{uid}
  role, phone, name, email?, defaultAddress, lat, lng, customerId?, shopId? (for staff)

shops/{shopId}
  name, address, lat, lng, phone, active, isListed
  subscriptionStatus, trialEndsAt, currentPeriodEndsAt, ownerUid

shops/{shopId}/products/{id}
shops/{shopId}/customers/{id}          // admin CRM record
shops/{shopId}/orders/{id}
shops/{shopId}/deliveries/{id}
shops/{shopId}/drivers/{id}

userFavorites/{uid}/shops/{shopId}

promotions/{id}                        // shopId null = platform-wide

appCustomers/{uid}                     // or embed in users
  phone, defaultAddress, lat, lng

customerShopLinks/{uid_shopId}
  uid, shopId, customerId              // one customer app login can link to multiple shops
```

### 8.3 Security rules (principles)

- Customer reads only shops linked to their admin-created monthly customer record.
- Customer writes only own orders under valid shop.
- Admin reads/writes only own `shopId`.
- Driver reads shop data + writes deliveries for assigned shop.
- Subscription status changed **only** by Cloud Function / admin SDK.

### 8.4 Indexes

- `shops`: `isListed` + `geo` (geohash later)
- `orders`: `shopId` + `status` + `createdAt`
- `orders`: `customerId` + `createdAt`

---

## 10. Mock layer now (before Firebase)

| Repository | Responsibility |
|--------------|----------------|
| `AuthRepository` | Staff + customer sessions |
| `WaterPlantRepository` | Shops, orders, deliveries, CRM customers |
| `NotificationRepository` | In-app notifications |
| `DeliveryRecordingService` | Save delivery + notify |
| `OrderWorkflowService` | Accept order + notify driver |

**Default shop:** Sri Sai RO Water Plant (`shop-1`) from `BusinessSettings`.

**Demo customer login:** phone `9876543210` · OTP `123456`

---

## 11. Routes (one app)

| Path | Screen |
|------|--------|
| `/login` | Staff sign-in |
| `/welcome` | Legacy redirect to `/login` |
| `/customer/login` | Phone OTP |
| `/customer/onboarding` | Profile + map |
| `/customer/home` | Shell: Home |
| `/customer/orders` | Shell: Orders |
| `/customer/profile` | Shell: Profile |
| `/customer/shop/:id` | Shop + order |
| `/driver/customers` | Driver home |
| `/driver/route` | Driver deliveries |
| `/` | Admin dashboard |

---

## 12. Implementation phases

| Phase | Deliverable |
|-------|-------------|
| **A** ✓ | Admin + Driver roles |
| **B** (current) | Master plan + Customer UI mock; customer entry paused |
| **C** | Monthly customer account polish + multi-admin customer links |
| **D** | Admin subscription mock UI |
| **E** | Firebase Auth + Firestore |
| **F** | Razorpay + multi-shop + promotions |

---

## 13. Success criteria (customer UI)

- New user understands in **5 seconds**: tap “Order water”.
- Onboarding completes in **under 2 minutes** (phone → address → pin).
- Placing order in **3 taps** from home (shop → qty → confirm).
- Visual style **matches admin** (navy header, white cards, Poppins).
- Staff never lands in customer flow by accident (separate entry).

---

## 14. Related docs

- [PRODUCT_ARCHITECTURE.md](PRODUCT_ARCHITECTURE.md) — roles & permissions
- [AGENTS.md](../AGENTS.md) — agent rules

---

*Update this document when scope changes.*
