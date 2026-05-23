# Closed Shop Customer UI Plan

## Purpose

Sri Sai RO Water is a closed water delivery management app for RO water plants, not a public marketplace.

The app replaces manual Excel sheets, handwritten customer cards, delivery trip notes, pricing records, monthly bills, and reports.

## Main Rule

Customers can see only the shop or shops that have added them.

A customer must not see all active water plants. Another shop appears in the customer app only when that shop admin adds or links the same customer.

## Roles

### Admin

- Creates customers.
- Creates drivers.
- Adds products.
- Sets customer-specific pricing.
- Views deliveries, orders, payments, bills, reports, and notifications.
- Receives notification when a driver saves a delivery.
- Pays subscription for the shop.

### Driver

- Created by admin.
- Views shop customers and route.
- Records daily delivered cans/products.
- Saves delivery and notifies admin/customer.
- Cannot manage products, prices, payments, bills, settings, or customer edits.
- Does not pay subscription.

### Customer

- Usually created by admin first.
- Logs in with phone.
- Sees only linked shop(s).
- Views deliveries, monthly activity, bills, payments, balance, and notifications.
- Can request/order water only from an admin-linked monthly customer account.
- Can be linked to multiple admins/plants when each admin adds the same phone number.
- Does not pay subscription.

## Current Concept Change

Old behavior:

- Customer can see all listed shops.

New behavior:

- Customer sees only admin-linked shop(s).

UI wording should change from public marketplace language to account/supplier language.

Use:

- Your water plant
- Linked shops
- Your supplier
- Request water
- Monthly activity
- Fixed customer
- Linked customer account
- Monthly customer

Avoid:

- Nearby shops
- Browse shops
- Featured shops
- Public ratings/reviews unless real
- App request customer type
- On-demand customer

## Mock Data Plan

Use existing mock data first.

Do not rewrite all mock data. Keep current customers, drivers, products, deliveries, orders, payments, and settings.

Add only the missing relationship data:

- Which shop owns each customer.
- Which shop owns each driver.
- Which app customer user is linked to which CRM customer.
- Which shop(s) a customer can see.
- Customer app orders must use an existing admin-created customer record.
- Customer app orders must remain part of monthly account activity and billing.
- The app must not create outside/public CRM customers automatically.

Optional small demo additions:

- One second shop.
- One customer linked only to the second shop.
- One customer linked to both shops.
- One customer linked to no shop, for empty-state testing.

Expected behavior:

- Customer linked to Sri Sai sees only Sri Sai.
- Customer linked to another plant sees only that plant.
- Customer linked to both sees both.
- Customer linked to no shop sees an empty state and contact message.

## Firebase Direction

Firebase is recommended for the production backend because the app needs Flutter support, authentication, real-time data, file storage, push notifications, and server-side workflows.

Recommended stack:

- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Cloud Functions
- Firebase Cloud Messaging
- Firebase App Check later
- Crashlytics and Analytics later

Use a multi-tenant structure from the beginning. Every important record should belong to a `shopId`.

Suggested structure:

```text
users/{uid}
shops/{shopId}
shops/{shopId}/customers/{customerId}
shops/{shopId}/drivers/{driverId}
shops/{shopId}/products/{productId}
shops/{shopId}/deliveries/{deliveryId}
shops/{shopId}/orders/{orderId}
shops/{shopId}/payments/{paymentId}
shops/{shopId}/notifications/{notificationId}
customerShopLinks/{linkId}
```

Security rules must enforce the same rule as the UI:

- Admin can access only owned shop data.
- Driver can access only allowed shop/customer delivery data.
- Customer can access only linked shop data and own records.

## Admin Subscription

Subscription applies only to admin/shop owner.

Customers do not pay. Drivers do not pay.

### Subscription States

- `trial`: full access during trial.
- `active`: full access after payment.
- `grace`: access continues with renewal banner.
- `expired`: admin sees renewal/paywall state.

Suggested shop fields:

```text
subscriptionStatus
trialEndsAt
currentPeriodEndsAt
planId
customerLimit
driverLimit
```

### Suggested Pricing

Starter:

- Rs. 499/month
- Up to 150 customers
- 1 driver

Standard:

- Rs. 999/month
- Up to 500 customers
- Up to 5 drivers
- Recommended MVP plan

Premium:

- Rs. 1,999/month
- Up to 1,500 customers
- More drivers
- Advanced reports
- Priority support

Offer:

- 30-day free trial.
- Optional early offer: Rs. 499/month for first 3 months.
- Optional annual plan: Rs. 9,999/year for Standard.

## Implementation Order

1. Create this planning doc.
2. Reuse existing mock data and add missing shop-customer links.
3. Add repository methods for linked shops.
4. Update customer home to show only linked shop(s).
5. Guard customer shop detail access.
6. Update customer shop/order UI language and customer-specific prices.
7. Update admin customer UI to show app access/linking clearly.
8. Confirm driver sees only allowed shop customers and delivery actions.
9. Add admin-only subscription mock UI.
10. Remove public/app-request customer type wording and keep fixed customers only.
11. Improve notifications for delivery/order workflows.
12. Unify premium UI tokens and reusable components.
13. Add responsive tablet/desktop improvements.
14. Prepare Firebase migration using the same data shape.

## First Code Step After This Doc

Start with mock data and repository logic:

- Keep current mock customers.
- Link existing customers to the default shop.
- Add a method that returns only shops linked to the logged-in customer.
- Do not update all UI screens at once.
