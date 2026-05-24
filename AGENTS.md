# Agent guide — Sri Sai RO Water

Before adding features, read **[docs/MASTER_PLAN.md](docs/MASTER_PLAN.md)**, **[docs/PRODUCT_ARCHITECTURE.md](docs/PRODUCT_ARCHITECTURE.md)**, and **[docs/PENDING_WORK.md](docs/PENDING_WORK.md)**.

**Quick rules**

- One app: **customer** (Order water) + **admin** + **driver** (Staff login).
- Premium UI: Poppins, white cards, navy admin header, **teal driver accent**.
- Enforce permissions in `AppPermissions`, router redirects, and UI (hide buttons).
- Drivers: view customers/orders; **add delivery only** — no payments, settings, or edits.
- Do not commit unless the user asks.
