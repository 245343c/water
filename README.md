# Sri Sai RO Water Plant

Flutter app + Node.js/MongoDB backend for RO water delivery — **admin**, **driver**, and **customer** roles in one app.

## Prerequisites

- [Flutter](https://flutter.dev) SDK
- [Node.js](https://nodejs.org) 18+
- [MongoDB](https://www.mongodb.com/) running locally (or Atlas URI in `backend/.env`)

## Backend setup

```bash
cd backend
cp .env.example .env
# Edit MONGO_URI and JWT_SECRET in .env
npm install
npm run seed
npm run dev
```

Server runs at `http://localhost:3000`. Health check: `GET http://localhost:3000/health`.

**Seed logins**

| Role | Credentials |
|------|-------------|
| Admin | `admin@srisai.com` / `admin123` |
| Driver | `driver@srisai.com` / `driver123` |
| Customer OTP | Phone `9999999999` (must exist in CRM) · OTP `123456` in dev |

## Flutter setup

```bash
flutter pub get
flutter run
```

### API URL (physical phone on USB/Wi‑Fi)

Default targets emulator/desktop (`localhost` or `10.0.2.2`). On a **real device**, point to your PC’s LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

See `lib/core/services/api/api_config.dart`.

## Testing

```bash
# Flutter
flutter analyze
flutter test

# Backend (server must be running + seeded)
cd backend
npm run test:smoke
```

## App roles

| Entry | Role | Main areas |
|-------|------|------------|
| Order water | Customer | Shops, place order, track status, profile |
| Staff login | Admin | Dashboard, customers, orders, products, deliveries, payments, reports |
| Staff login | Driver | Route, customers, record deliveries only |

## Docs

- [docs/PENDING_WORK.md](docs/PENDING_WORK.md) — backlog by phase
- [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md) — product vision
- [docs/PRODUCT_ARCHITECTURE.md](docs/PRODUCT_ARCHITECTURE.md) — roles & permissions
- [docs/BACKEND_MIGRATION_STATUS.md](docs/BACKEND_MIGRATION_STATUS.md) — API wiring status

## Notes

- All business data uses the **backend API** (`useBackend = true`). No in-app mock data store.
- Subscription/Razorpay and FCM push are **not** production-ready yet (see pending work).
- Customer OTP is returned in API responses in **development** only; use SMS in production.
