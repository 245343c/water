const assert = require("assert");
const fs = require("fs");
const path = require("path");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");

describe("Firestore staff access rules", () => {
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: "sri-sai-ro-water-rules-test",
      firestore: {
        rules: fs.readFileSync(
          path.join(__dirname, "..", "..", "firestore.rules"),
          "utf8",
        ),
      },
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("users/admin-a").set({
        role: "admin",
        shopId: "shop-a",
        active: true,
      });
      await db.doc("users/driver-a").set({
        role: "driver",
        shopId: "shop-a",
        driverId: "driver-1",
        active: true,
      });
      await db.doc("users/driver-inactive").set({
        role: "driver",
        shopId: "shop-a",
        driverId: "driver-off",
        active: false,
      });
      await db.doc("shops/shop-a").set({
        name: "Shop A",
        ownerUid: "admin-a",
      });
      await db.doc("shops/shop-b").set({
        name: "Shop B",
        ownerUid: "admin-b",
      });
      await db.doc("shops/shop-a/customers/customer-1").set({
        name: "Customer One",
        active: true,
      });
      await db.doc("shops/shop-b/customers/customer-2").set({
        name: "Customer Two",
        active: true,
      });
      await db.doc("shops/shop-a/orders/order-driver-1").set({
        customerId: "customer-1",
        status: "accepted",
        driverId: "driver-1",
        fulfilledAt: null,
      });
      await db.doc("shops/shop-a/orders/order-driver-2").set({
        customerId: "customer-1",
        status: "accepted",
        driverId: "driver-2",
        fulfilledAt: null,
      });
      await db.doc("shops/shop-a/orders/order-pending").set({
        customerId: "customer-1",
        status: "pending",
        driverId: "driver-1",
        fulfilledAt: null,
      });
      await db.doc("shops/shop-a/payments/payment-1").set({
        customerId: "customer-1",
        amount: 100,
      });
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  function adminDb() {
    return testEnv
      .authenticatedContext("admin-a", { email_verified: true })
      .firestore();
  }

  function driverDb(uid = "driver-a") {
    return testEnv.authenticatedContext(uid).firestore();
  }

  it("allows a verified admin to read and write only their own shop data", async () => {
    await assertSucceeds(adminDb().doc("shops/shop-a/customers/customer-1").get());
    await assertSucceeds(
      adminDb().doc("shops/shop-a/customers/customer-new").set({
        name: "New Customer",
        active: true,
      }),
    );
    await assertFails(adminDb().doc("shops/shop-b/customers/customer-2").get());
  });

  it("allows an active driver to read assigned open orders only", async () => {
    await assertSucceeds(
      driverDb().doc("shops/shop-a/orders/order-driver-1").get(),
    );
    await assertFails(driverDb().doc("shops/shop-a/orders/order-driver-2").get());
    await assertFails(driverDb().doc("shops/shop-a/orders/order-pending").get());
  });

  it("requires driver order queries to include the secure driver filters", async () => {
    const allowedQuery = driverDb()
      .collection("shops/shop-a/orders")
      .where("driverId", "==", "driver-1")
      .where("status", "==", "accepted")
      .where("fulfilledAt", "==", null);

    const broadQuery = driverDb()
      .collection("shops/shop-a/orders")
      .where("status", "==", "accepted");

    await assertSucceeds(allowedQuery.get());
    await assertFails(broadQuery.get());
  });

  it("does not allow drivers to write customers or read payments", async () => {
    await assertFails(
      driverDb().doc("shops/shop-a/customers/customer-1").set({
        name: "Edited",
      }),
    );
    await assertFails(driverDb().doc("shops/shop-a/payments/payment-1").get());
  });

  it("denies inactive driver access", async () => {
    await assertFails(
      driverDb("driver-inactive").doc("shops/shop-a/orders/order-driver-1").get(),
    );
  });

  it("keeps tests honest", () => {
    assert.ok(testEnv, "test environment should be initialized");
  });
});
