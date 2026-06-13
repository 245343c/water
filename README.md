# Sri Sai RO Water Plant

Flutter app for RO water delivery — admin dashboard, customer CRM, billing, drivers, and field delivery. **Firebase-backed** (Auth, Firestore, Cloud Functions, FCM).

**Current release:** admin + driver only. Customer portal routes are paused; customer records are still managed from admin/driver screens.

## Prerequisites

- Flutter SDK 3.11+ (`flutter doctor`)
- Firebase project with Auth (Email/Password + Phone), Firestore, Functions, and FCM enabled
- FlutterFire config: `lib/firebase_options.dart`, `android/app/google-services.json`, iOS/macOS `GoogleService-Info.plist`

## Run locally

```bash
cd c:\Users\91833\Documents\water
flutter pub get
flutter run
```

Hot reload: `r` · Hot restart: `R`

## Deploy Firebase backend

From the repo root (requires [Firebase CLI](https://firebase.google.com/docs/cli) and project selected):

```bash
firebase deploy --only firestore:rules,firestore:indexes,functions
```

Cloud Functions run in **`asia-south1`**. The Flutter app uses the same region via `FirebaseBackend`.

## Staff flows (production)

| Flow | How it works |
|------|----------------|
| **Admin signup** | `/register` → mobile OTP → `completeAdminRegistration` Cloud Function → sign in with **mobile + password** |
| **Admin / driver login** | `/login` with mobile number (or email) + password |
| **Forgot password** | Mobile number or registered email → Firebase reset email (uses internal auth email for phone-only accounts) |
| **Customers** | Admin creates in Firestore (`shops/{id}/customers`); real-time list sync |
| **Deliveries & payments** | Written via Cloud Functions (`recordCustomerDelivery`, `recordCustomerPayment`) |
| **Drivers** | Admin creates via `createDriverAccount`; driver logs in with mobile + password |
| **Walk-in / instant dispatch** | Admin `createWalkInDispatch` → driver `fulfillDispatchOrder` |
| **Notifications** | Firestore `notifications` + FCM push (`registerFcmToken`) |

## Roles & routes

- **Admin:** `/` dashboard · `/customers` · `/orders` · `/products` · `/more`
- **Driver:** `/driver/customers` · `/driver/route` · `/driver/profile`
- Permissions: `AppPermissions` + `route_guard.dart` + UI hiding

## Project docs

- [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md) — product scope
- [docs/PRODUCT_ARCHITECTURE.md](docs/PRODUCT_ARCHITECTURE.md) — roles, permissions, routing

## Development toggles

`lib/core/config/app_config.dart`:

- `useInstantDispatchMock = false` — use Firebase for instant dispatch (keep `false` in production)

## Tests

```bash
flutter analyze
flutter test
```

Customer UI tests are skipped intentionally for this release.
