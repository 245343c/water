"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const callableOptions = {
  invoker: "public",
  region: "asia-south1",
  maxInstances: 3,
};

async function requireAdmin(auth) {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in as admin first.");
  }

  const userSnap = await db.collection("users").doc(auth.uid).get();
  const user = userSnap.data();
  if (!user || user.role !== "admin" || !user.shopId) {
    throw new HttpsError("permission-denied", "Admin access required.");
  }

  return { uid: auth.uid, shopId: user.shopId };
}

async function requireShopStaff(auth, { allowDriver = false } = {}) {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }

  const userSnap = await db.collection("users").doc(auth.uid).get();
  const user = userSnap.data();
  const allowedRoles = allowDriver ? ["admin", "driver"] : ["admin"];
  if (!user || !allowedRoles.includes(user.role) || !user.shopId) {
    throw new HttpsError("permission-denied", "Shop staff access required.");
  }

  return {
    uid: auth.uid,
    role: user.role,
    shopId: user.shopId,
    driverId: user.driverId || null,
  };
}

function cleanText(value, field, minLength = 1) {
  const text = String(value || "").trim();
  if (text.length < minLength) {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  return text;
}

function cleanEmail(value) {
  const email = cleanText(value, "Email").toLowerCase();
  if (!email.includes("@")) {
    throw new HttpsError("invalid-argument", "Enter a valid email.");
  }
  return email;
}

function cleanOptionalEmail(value) {
  const email = String(value || "").trim().toLowerCase();
  if (!email) return "";
  if (!email.includes("@")) {
    throw new HttpsError("invalid-argument", "Enter a valid email.");
  }
  return email;
}

function normalizePhone(value) {
  const digits = String(value || "").replace(/\D/g, "");
  if (digits.length !== 10) {
    throw new HttpsError(
      "invalid-argument",
      "Enter exactly 10 mobile digits.",
    );
  }
  return digits;
}

function normalizeAuthPhone(value) {
  const digits = String(value || "").replace(/\D/g, "");
  if (digits.length === 12 && digits.startsWith("91")) {
    return normalizePhone(digits.slice(2));
  }
  return normalizePhone(digits);
}

function driverAuthEmail(phoneDigits) {
  return `driver_${phoneDigits}@waterapp.local`;
}

function cleanPassword(value) {
  const password = String(value || "");
  if (password.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "Password must be at least 6 characters.",
    );
  }
  return password;
}

function driverPayload(driverId, data) {
  return {
    id: driverId,
    name: data.name || "",
    phone: data.phone || "",
    email: data.email || "",
    active: data.active !== false,
    uid: data.uid || null,
  };
}

function paymentPayload(paymentId, data) {
  const date = data.date && data.date.toDate ? data.date.toDate() : data.date;
  const createdAt = data.createdAt && data.createdAt.toDate
    ? data.createdAt.toDate()
    : data.createdAt;
  return {
    id: paymentId,
    customerId: data.customerId || "",
    amount: data.amount || 0,
    method: data.method || "cash",
    notes: data.notes || "",
    date: date instanceof Date ? date.toISOString() : "",
    createdAt: createdAt instanceof Date ? createdAt.toISOString() : "",
  };
}

function deliveryPayload(deliveryId, data) {
  const date = data.date && data.date.toDate ? data.date.toDate() : data.date;
  const createdAt = data.createdAt && data.createdAt.toDate
    ? data.createdAt.toDate()
    : data.createdAt;
  return {
    id: deliveryId,
    customerId: data.customerId || "",
    lines: data.lines || [],
    emptyNormalReturned: Number(data.emptyNormalReturned) || 0,
    emptyCoolReturned: Number(data.emptyCoolReturned) || 0,
    driverId: data.driverId || null,
    date: date instanceof Date ? date.toISOString() : "",
    createdAt: createdAt instanceof Date ? createdAt.toISOString() : "",
  };
}

function cleanEmptyCanCount(value) {
  const count = Number(value);
  if (!Number.isInteger(count) || count < 0) return 0;
  return count;
}

function orderPayload(orderId, data) {
  const createdAt = data.createdAt && data.createdAt.toDate
    ? data.createdAt.toDate()
    : data.createdAt;
  const respondedAt = data.respondedAt && data.respondedAt.toDate
    ? data.respondedAt.toDate()
    : data.respondedAt;
  const driverAcceptedAt = data.driverAcceptedAt && data.driverAcceptedAt.toDate
    ? data.driverAcceptedAt.toDate()
    : data.driverAcceptedAt;
  const deliveryStartedAt = data.deliveryStartedAt && data.deliveryStartedAt.toDate
    ? data.deliveryStartedAt.toDate()
    : data.deliveryStartedAt;
  return {
    id: orderId,
    customerId: data.customerId || "",
    shopId: data.shopId || "",
    placedByAppUserId: data.placedByAppUserId || "",
    normalQty: data.normalQty || 0,
    coolQty: data.coolQty || 0,
    status: data.status || "pending",
    customerNote: data.customerNote || "",
    adminResponse: data.adminResponse || "",
    createdAt: createdAt instanceof Date ? createdAt.toISOString() : "",
    respondedAt: respondedAt instanceof Date ? respondedAt.toISOString() : "",
    driverAcceptedAt: driverAcceptedAt instanceof Date
      ? driverAcceptedAt.toISOString()
      : "",
    deliveryStartedAt: deliveryStartedAt instanceof Date
      ? deliveryStartedAt.toISOString()
      : "",
  };
}

function customerPayload(customerId, data) {
  return {
    id: customerId,
    name: data.name || "",
    phone: data.phone || "",
    email: data.email || "",
    place: data.place || "",
    routeId: data.routeId || null,
    address: data.address || "",
    paymentFrequency: data.paymentFrequency || "Monthly",
    billingMode: data.billingMode || "monthlyContract",
    productPrices: data.productPrices || [],
    appUserId: data.appUserId || null,
  };
}

function shopPayload(shopId, data) {
  const trialEndsAt = data.trialEndsAt && data.trialEndsAt.toDate
    ? data.trialEndsAt.toDate()
    : data.trialEndsAt;
  return {
    id: shopId,
    name: data.name || "",
    address: data.address || "",
    phone: data.phone || "",
    email: data.email || "",
    place: data.place || "",
    latitude: data.latitude || null,
    longitude: data.longitude || null,
    subscriptionStatus: data.subscriptionStatus || "trial",
    trialEndsAt: trialEndsAt instanceof Date ? trialEndsAt.toISOString() : "",
    isListed: data.isListed !== false,
    homeDeliveryAvailable: data.homeDeliveryAvailable === true,
    normalPrice: data.normalPrice || 20,
    coolPrice: data.coolPrice || 30,
    coverImageUrl: data.coverImageUrl || null,
    tagline: data.tagline || "",
    rating: data.rating || 4.5,
    reviewCount: data.reviewCount || 0,
  };
}

function productPayload(productId, data) {
  return {
    id: productId,
    name: data.name || "",
    description: data.description || "",
    category: data.category || "bottle",
    variants: data.variants || [],
    active: data.active !== false,
  };
}

function cleanAmount(value) {
  const amount = Number(value);
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new HttpsError("invalid-argument", "Enter a valid payment amount.");
  }
  return amount;
}

function cleanPaymentMethod(value) {
  const method = String(value || "cash").trim().toLowerCase();
  if (!["cash", "upi", "other"].includes(method)) {
    throw new HttpsError("invalid-argument", "Enter a valid payment method.");
  }
  return method;
}

function cleanDate(value, field) {
  const date = new Date(String(value || ""));
  if (Number.isNaN(date.getTime())) {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  return date;
}

function monthSummaryRef(shopId, customerId, date) {
  const year = date.getFullYear();
  const month = date.getMonth() + 1;
  const monthKey = `${year}${String(month).padStart(2, "0")}`;
  return {
    ref: db
      .collection("shops")
      .doc(shopId)
      .collection("customers")
      .doc(customerId)
      .collection("monthlySummaries")
      .doc(monthKey),
    monthKey,
    year,
    month,
  };
}

function baseMonthlySummary(shopId, customerId, date) {
  const summary = monthSummaryRef(shopId, customerId, date);
  return {
    ref: summary.ref,
    data: {
      shopId,
      customerId,
      monthKey: summary.monthKey,
      year: summary.year,
      month: summary.month,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  };
}

function cleanDeliveryLines(value) {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpsError("invalid-argument", "At least one delivery item is required.");
  }

  return value.map((raw) => {
    const item = raw || {};
    const kind = String(item.kind || "").trim();
    if (!["normalCan", "coolCan", "bottle"].includes(kind)) {
      throw new HttpsError("invalid-argument", "Invalid delivery item type.");
    }

    const quantity = Number(item.quantity);
    const unitPrice = Number(item.unitPrice);
    if (!Number.isInteger(quantity) || quantity <= 0) {
      throw new HttpsError("invalid-argument", "Invalid delivery quantity.");
    }
    if (!Number.isFinite(unitPrice) || unitPrice < 0) {
      throw new HttpsError("invalid-argument", "Invalid delivery price.");
    }

    return {
      kind,
      label: cleanText(item.label, "Delivery item"),
      quantity,
      unitPrice,
      lineTotal: quantity * unitPrice,
      productId: item.productId ? String(item.productId).trim() : null,
    };
  });
}

function deliveryTotals(lines) {
  return lines.reduce(
    (totals, line) => {
      if (line.kind === "normalCan") totals.normalQty += line.quantity;
      if (line.kind === "coolCan") totals.coolQty += line.quantity;
      if (line.kind === "bottle") totals.bottleQty += line.quantity;
      totals.totalAmount += line.lineTotal;
      return totals;
    },
    { normalQty: 0, coolQty: 0, bottleQty: 0, totalAmount: 0 },
  );
}

function customerPrice(customer, productId, variantId, fallback) {
  const prices = Array.isArray(customer.productPrices)
    ? customer.productPrices
    : [];
  const match = prices.find((price) =>
    price &&
    price.enabled !== false &&
    price.productId === productId &&
    price.variantId === variantId);
  const value = Number(match?.unitPrice);
  return Number.isFinite(value) && value >= 0 ? value : fallback;
}

async function applyCanonicalDeliveryPrices(shopId, customer, lines) {
  const shopSnap = await db.collection("shops").doc(shopId).get();
  const shop = shopSnap.data() || {};
  const normalPrice = Number(shop.normalPrice) || 20;
  const coolPrice = Number(shop.coolPrice) || 30;

  return Promise.all(lines.map(async (line) => {
    let unitPrice;
    if (line.kind === "normalCan") {
      unitPrice = customerPrice(
        customer,
        "__water_cans__",
        "normal",
        normalPrice,
      );
    } else if (line.kind === "coolCan") {
      unitPrice = customerPrice(
        customer,
        "__water_cans__",
        "cool",
        coolPrice,
      );
    } else {
      if (!line.productId) {
        throw new HttpsError("invalid-argument", "Bottle product is required.");
      }
      const productSnap = await db
        .collection("shops")
        .doc(shopId)
        .collection("products")
        .doc(line.productId)
        .get();
      const product = productSnap.data();
      if (!product || product.active === false) {
        throw new HttpsError("invalid-argument", "Bottle product is not available.");
      }
      const allowedPrices = (Array.isArray(customer.productPrices)
        ? customer.productPrices
        : [])
        .filter((price) =>
          price &&
          price.enabled !== false &&
          price.productId === line.productId &&
          Number.isFinite(Number(price.unitPrice)) &&
          Number(price.unitPrice) >= 0);
      const selectedPrice = allowedPrices.find(
        (price) => Number(price.unitPrice) === line.unitPrice,
      ) || (allowedPrices.length === 1 ? allowedPrices[0] : null);
      if (!selectedPrice) {
        throw new HttpsError(
          "invalid-argument",
          "Bottle price is not configured for this customer.",
        );
      }
      unitPrice = Number(selectedPrice.unitPrice);
    }

    return {
      ...line,
      unitPrice,
      lineTotal: line.quantity * unitPrice,
    };
  }));
}

function deliveryCansSummary(totals) {
  const parts = [];
  if (totals.normalQty > 0) parts.push(`${totals.normalQty} Normal`);
  if (totals.coolQty > 0) parts.push(`${totals.coolQty} Cool`);
  return parts.length > 0 ? parts.join(" · ") : "Delivery recorded";
}

async function resolveDriverName(shopId, driverId, fallbackName) {
  const fallback = String(fallbackName || "").trim();
  if (!driverId) return fallback || "Staff";
  const driverSnap = await db
    .collection("shops")
    .doc(shopId)
    .collection("drivers")
    .doc(driverId)
    .get();
  return driverSnap.data()?.name || fallback || "Driver";
}

function appendDeliveryNotifications({
  batch,
  shopId,
  customerId,
  customerName,
  deliveryId,
  driverId,
  driverName,
  summary,
  amount,
  now,
}) {
  const notificationsRef = db
    .collection("shops")
    .doc(shopId)
    .collection("notifications");
  const roundedAmount = Math.round(amount);

  batch.set(notificationsRef.doc(), {
    shopId,
    type: "deliveryRecorded",
    audience: "admin",
    title: "Delivery recorded",
    body: `${driverName} delivered ${summary} to ${customerName}. Bill ₹${roundedAmount} updated.`,
    customerId,
    deliveryId,
    driverId: driverId || null,
    driverName: driverName || null,
    read: false,
    createdAt: now,
    updatedAt: now,
  });

  batch.set(notificationsRef.doc(), {
    shopId,
    type: "deliveryRecorded",
    audience: "customer",
    title: "Water delivered today",
    body: `${summary} delivered to your address. Amount ₹${roundedAmount} added to your account.`,
    customerId,
    deliveryId,
    driverId: driverId || null,
    driverName: driverName || null,
    read: false,
    createdAt: now,
    updatedAt: now,
  });
}

function appendOrderNotification({
  batch,
  shopId,
  type,
  audience,
  title,
  body,
  customerId,
  orderId,
  now,
}) {
  batch.set(
    db.collection("shops").doc(shopId).collection("notifications").doc(),
    {
      shopId,
      type,
      audience,
      title,
      body,
      customerId,
      orderId,
      read: false,
      createdAt: now,
      updatedAt: now,
    },
  );
}

async function customerLinksForUid(uid) {
  const linksSnap = await db
    .collection("customerShopLinks")
    .where("uid", "==", uid)
    .where("active", "==", true)
    .get();
  return linksSnap.docs.map((doc) => doc.data());
}

async function customerPortalLinks(uid) {
  const links = [];
  for (const link of await customerLinksForUid(uid)) {
    const shopId = link.shopId;
    const customerId = link.customerId;
    if (!shopId || !customerId) continue;

    const shopRef = db.collection("shops").doc(shopId);
    const [
      shopSnap,
      customerSnap,
      deliveriesSnap,
      paymentsSnap,
      ordersSnap,
      productsSnap,
    ] =
      await Promise.all([
        shopRef.get(),
        shopRef.collection("customers").doc(customerId).get(),
        shopRef
          .collection("deliveries")
          .where("customerId", "==", customerId)
          .limit(250)
          .get(),
        shopRef
          .collection("payments")
          .where("customerId", "==", customerId)
          .limit(250)
          .get(),
        shopRef
          .collection("orders")
          .where("customerId", "==", customerId)
          .limit(250)
          .get(),
        shopRef.collection("products").where("active", "==", true).limit(100).get(),
      ]);

    const shop = shopSnap.data();
    const customer = customerSnap.data();
    if (!shop || !customer || customer.active === false) continue;
    links.push({
      shop: shopPayload(shopSnap.id, shop),
      customer: customerPayload(customerSnap.id, customer),
      deliveries: deliveriesSnap.docs.map((doc) =>
        deliveryPayload(doc.id, doc.data()),
      ),
      payments: paymentsSnap.docs.map((doc) =>
        paymentPayload(doc.id, doc.data()),
      ),
      orders: ordersSnap.docs.map((doc) => orderPayload(doc.id, doc.data())),
      products: productsSnap.docs.map((doc) =>
        productPayload(doc.id, doc.data()),
      ),
    });
  }
  return links;
}

async function requireCustomer(auth) {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in as customer first.");
  }
  const userSnap = await db.collection("users").doc(auth.uid).get();
  const user = userSnap.data();
  if (!user || user.role !== "customer") {
    throw new HttpsError("permission-denied", "Customer access required.");
  }
  return { uid: auth.uid, user };
}

async function requireLinkedCustomer(uid, shopId, customerId) {
  const links = await customerLinksForUid(uid);
  const linked = links.some((link) =>
    link.shopId === shopId && link.customerId === customerId);
  if (!linked) {
    throw new HttpsError("permission-denied", "Customer is not linked to this shop.");
  }
}

function mapAuthError(error) {
  switch (error.code) {
    case "auth/email-already-exists":
      return new HttpsError("already-exists", "Email already has an account.");
    case "auth/invalid-email":
      return new HttpsError("invalid-argument", "Enter a valid email.");
    case "auth/invalid-password":
    case "auth/weak-password":
      return new HttpsError(
        "invalid-argument",
        "Password must be at least 6 characters.",
      );
    case "auth/operation-not-allowed":
      return new HttpsError(
        "failed-precondition",
        "Email/password sign-in is not enabled in Firebase Authentication.",
      );
    default:
      return null;
  }
}

function logFunctionError(functionName, error) {
  console.error(`${functionName} failed`, {
    code: error.code,
    message: error.message,
    stack: error.stack,
  });
}

async function getDriverForAdmin(adminCtx, driverId) {
  const driverRef = db
    .collection("shops")
    .doc(adminCtx.shopId)
    .collection("drivers")
    .doc(driverId);
  const driverSnap = await driverRef.get();
  const driver = driverSnap.data();
  if (!driver || !driver.uid) {
    throw new HttpsError("not-found", "Driver not found.");
  }
  return { driverRef, driver };
}

exports.createDriverAccount = onCall(callableOptions, async (request) => {
  const adminCtx = await requireAdmin(request.auth);
  const name = cleanText(request.data.name, "Name");
  const phone = cleanText(request.data.phone, "Phone", 10);
  const normalizedPhone = normalizePhone(phone);
  const email = cleanOptionalEmail(request.data.email);
  const authEmail = driverAuthEmail(normalizedPhone);
  const password = cleanPassword(request.data.password);

  const driverRef = db
    .collection("shops")
    .doc(adminCtx.shopId)
    .collection("drivers")
    .doc();

  let authUser;
  try {
    authUser = await admin.auth().createUser({
      email: authEmail,
      password,
      displayName: name,
      disabled: false,
    });

    await admin.auth().setCustomUserClaims(authUser.uid, {
      role: "driver",
      shopId: adminCtx.shopId,
      driverId: driverRef.id,
    });

    const now = admin.firestore.FieldValue.serverTimestamp();
    const batch = db.batch();
    batch.set(driverRef, {
      uid: authUser.uid,
      name,
      phone,
      normalizedPhone,
      email,
      authEmail,
      active: true,
      createdAt: now,
      updatedAt: now,
      createdBy: adminCtx.uid,
    });
    batch.set(db.collection("users").doc(authUser.uid), {
      role: "driver",
      name,
      phone,
      normalizedPhone,
      email,
      authEmail,
      businessName: "",
      shopId: adminCtx.shopId,
      driverId: driverRef.id,
      active: true,
      createdAt: now,
      updatedAt: now,
      createdBy: adminCtx.uid,
    });
    await batch.commit();

    return driverPayload(driverRef.id, {
      uid: authUser.uid,
      name,
      phone,
      email,
      active: true,
    });
  } catch (error) {
    if (authUser) {
      await admin.auth().deleteUser(authUser.uid).catch(() => {});
    }
    if (error instanceof HttpsError) {
      throw error;
    }
    const authError = mapAuthError(error);
    if (authError && error.code === "auth/email-already-exists") {
      throw new HttpsError(
        "already-exists",
        "Mobile number already has a driver account.",
      );
    }
    if (authError) throw authError;
    logFunctionError("createDriverAccount", error);
    throw new HttpsError("internal", error.message || "Driver not created.");
  }
});

exports.updateDriverAccount = onCall(callableOptions, async (request) => {
  const adminCtx = await requireAdmin(request.auth);
  const driverId = cleanText(request.data.driverId, "Driver id");
  const name = cleanText(request.data.name, "Name");
  const phone = cleanText(request.data.phone, "Phone", 10);
  const normalizedPhone = normalizePhone(phone);
  const email = cleanOptionalEmail(request.data.email);
  const authEmail = driverAuthEmail(normalizedPhone);

  const { driverRef, driver } = await getDriverForAdmin(adminCtx, driverId);

  try {
    await admin.auth().updateUser(driver.uid, {
      email: authEmail,
      displayName: name,
    });
  } catch (error) {
    const authError = mapAuthError(error);
    if (authError && error.code === "auth/email-already-exists") {
      throw new HttpsError(
        "already-exists",
        "Mobile number already has a driver account.",
      );
    }
    if (authError) throw authError;
    logFunctionError("updateDriverAccount", error);
    throw new HttpsError("internal", error.message || "Driver not updated.");
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  await db.runTransaction(async (tx) => {
    tx.set(
      driverRef,
      { name, phone, normalizedPhone, email, authEmail, updatedAt: now },
      { merge: true },
    );
    tx.set(
      db.collection("users").doc(driver.uid),
      { name, phone, normalizedPhone, email, authEmail, updatedAt: now },
      { merge: true },
    );
  });

  return driverPayload(driverId, {
    uid: driver.uid,
    name,
    phone,
    email,
    active: driver.active,
  });
});

exports.setDriverActive = onCall(callableOptions, async (request) => {
  const adminCtx = await requireAdmin(request.auth);
  const driverId = cleanText(request.data.driverId, "Driver id");
  const active = request.data.active === true;

  const { driverRef, driver } = await getDriverForAdmin(adminCtx, driverId);

  await admin.auth().updateUser(driver.uid, { disabled: !active });

  const now = admin.firestore.FieldValue.serverTimestamp();
  await db.runTransaction(async (tx) => {
    tx.set(driverRef, { active, updatedAt: now }, { merge: true });
    tx.set(
      db.collection("users").doc(driver.uid),
      { active, updatedAt: now },
      { merge: true },
    );
  });

  return { driverId, active };
});

exports.deleteDriverAccount = onCall(callableOptions, async (request) => {
  const adminCtx = await requireAdmin(request.auth);
  const driverId = cleanText(request.data.driverId, "Driver id");

  const { driverRef, driver } = await getDriverForAdmin(adminCtx, driverId);

  await admin.auth().updateUser(driver.uid, { disabled: true });

  const now = admin.firestore.FieldValue.serverTimestamp();
  await db.runTransaction(async (tx) => {
    tx.set(driverRef, { active: false, deletedAt: now }, { merge: true });
    tx.set(
      db.collection("users").doc(driver.uid),
      { active: false, deletedAt: now },
      { merge: true },
    );
  });

  return { driverId, active: false };
});

exports.resetDriverPassword = onCall(callableOptions, async (request) => {
  const adminCtx = await requireAdmin(request.auth);
  const driverId = cleanText(request.data.driverId, "Driver id");
  const password = cleanPassword(request.data.password);
  const { driverRef, driver } = await getDriverForAdmin(adminCtx, driverId);

  try {
    await admin.auth().updateUser(driver.uid, { password });
  } catch (error) {
    const authError = mapAuthError(error);
    if (authError) throw authError;
    logFunctionError("resetDriverPassword", error);
    throw new HttpsError("internal", error.message || "Password not reset.");
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  await db.runTransaction(async (tx) => {
    tx.set(
      driverRef,
      { passwordResetAt: now, passwordResetBy: adminCtx.uid, updatedAt: now },
      { merge: true },
    );
    tx.set(
      db.collection("users").doc(driver.uid),
      { passwordResetAt: now, passwordResetBy: adminCtx.uid, updatedAt: now },
      { merge: true },
    );
  });

  return { driverId };
});

exports.recordCustomerPayment = onCall(callableOptions, async (request) => {
  const adminCtx = await requireAdmin(request.auth);
  const customerId = cleanText(request.data.customerId, "Customer id");
  const amount = cleanAmount(request.data.amount);
  const method = cleanPaymentMethod(request.data.method);
  const date = cleanDate(request.data.date, "Payment date");
  const notes = String(request.data.notes || "").trim();

  const customerRef = db
    .collection("shops")
    .doc(adminCtx.shopId)
    .collection("customers")
    .doc(customerId);
  const customerSnap = await customerRef.get();
  const customer = customerSnap.data();
  if (!customer || customer.active === false) {
    throw new HttpsError("not-found", "Customer not found.");
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const paymentRef = db
    .collection("shops")
    .doc(adminCtx.shopId)
    .collection("payments")
    .doc();
  const monthlySummary = baseMonthlySummary(adminCtx.shopId, customerId, date);
  const payment = {
    shopId: adminCtx.shopId,
    customerId,
    amount,
    method,
    notes,
    date: admin.firestore.Timestamp.fromDate(date),
    createdAt: now,
    updatedAt: now,
    createdBy: adminCtx.uid,
  };

  const batch = db.batch();
  batch.set(paymentRef, payment);
  batch.set(
    monthlySummary.ref,
    {
      ...monthlySummary.data,
      paymentCount: admin.firestore.FieldValue.increment(1),
      paymentAmount: admin.firestore.FieldValue.increment(amount),
    },
    { merge: true },
  );
  await batch.commit();

  return paymentPayload(paymentRef.id, {
    ...payment,
    createdAt: new Date(),
  });
});

exports.recordCustomerDelivery = onCall(callableOptions, async (request) => {
  const staffCtx = await requireShopStaff(request.auth, { allowDriver: true });
  if (request.data.action === "updateOrderProgress") {
    if (staffCtx.role !== "driver") {
      throw new HttpsError("permission-denied", "Driver access required.");
    }
    const orderId = cleanText(request.data.orderId, "Order id");
    const progress = cleanText(request.data.progress, "Progress");
    if (!["accepted", "started"].includes(progress)) {
      throw new HttpsError("invalid-argument", "Unsupported delivery progress.");
    }
    const orderRef = db
      .collection("shops")
      .doc(staffCtx.shopId)
      .collection("orders")
      .doc(orderId);
    const orderSnap = await orderRef.get();
    const order = orderSnap.data();
    if (!order || order.status !== "accepted") {
      throw new HttpsError("failed-precondition", "Accepted request not found.");
    }
    const now = admin.firestore.FieldValue.serverTimestamp();
    const updates = {
      driverId: staffCtx.driverId,
      driverAcceptedAt: now,
      updatedAt: now,
    };
    if (progress === "started") {
      updates.deliveryStartedAt = now;
    }
    await orderRef.set(updates, { merge: true });
    return orderPayload(orderId, {
      ...order,
      driverId: staffCtx.driverId,
      driverAcceptedAt: new Date(),
      deliveryStartedAt: progress === "started"
        ? new Date()
        : order.deliveryStartedAt,
    });
  }

  const customerId = cleanText(request.data.customerId, "Customer id");
  const date = cleanDate(request.data.date, "Delivery date");
  const emptyNormalReturned = cleanEmptyCanCount(request.data.emptyNormalReturned);
  const emptyCoolReturned = cleanEmptyCanCount(request.data.emptyCoolReturned);
  let lines = Array.isArray(request.data.lines) ? request.data.lines : [];

  if (lines.length > 0) {
    lines = cleanDeliveryLines(lines);
  } else if (emptyNormalReturned + emptyCoolReturned <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "Add delivery items or record empty can returns.",
    );
  } else {
    lines = [];
  }

  const customerRef = db
    .collection("shops")
    .doc(staffCtx.shopId)
    .collection("customers")
    .doc(customerId);
  const customerSnap = await customerRef.get();
  const customer = customerSnap.data();
  if (!customer || customer.active === false) {
    throw new HttpsError("not-found", "Customer not found.");
  }
  if (lines.length > 0) {
    lines = await applyCanonicalDeliveryPrices(staffCtx.shopId, customer, lines);
  }
  const totals = deliveryTotals(lines);

  const now = admin.firestore.FieldValue.serverTimestamp();
  const deliveryRef = db
    .collection("shops")
    .doc(staffCtx.shopId)
    .collection("deliveries")
    .doc();
  const monthlySummary = baseMonthlySummary(staffCtx.shopId, customerId, date);
  const delivery = {
    shopId: staffCtx.shopId,
    customerId,
    date: admin.firestore.Timestamp.fromDate(date),
    lines,
    emptyNormalReturned,
    emptyCoolReturned,
    normalQty: totals.normalQty,
    coolQty: totals.coolQty,
    bottleQty: totals.bottleQty,
    totalAmount: totals.totalAmount,
    driverId: staffCtx.role === "driver"
      ? staffCtx.driverId
      : (request.data.driverId || null),
    createdAt: now,
    updatedAt: now,
    createdBy: staffCtx.uid,
  };

  const driverId = staffCtx.role === "driver"
    ? staffCtx.driverId
    : (request.data.driverId || null);
  const driverName = await resolveDriverName(
    staffCtx.shopId,
    driverId,
    request.data.driverName,
  );
  const summary = deliveryCansSummary(totals);

  const batch = db.batch();
  batch.set(deliveryRef, { ...delivery, driverId });
  batch.set(
    monthlySummary.ref,
    {
      ...monthlySummary.data,
      deliveryCount: admin.firestore.FieldValue.increment(1),
      normalQty: admin.firestore.FieldValue.increment(totals.normalQty),
      coolQty: admin.firestore.FieldValue.increment(totals.coolQty),
      bottleQty: admin.firestore.FieldValue.increment(totals.bottleQty),
      deliveryAmount: admin.firestore.FieldValue.increment(totals.totalAmount),
    },
    { merge: true },
  );
  appendDeliveryNotifications({
    batch,
    shopId: staffCtx.shopId,
    customerId,
    customerName: customer.name || "Customer",
    deliveryId: deliveryRef.id,
    driverId,
    driverName,
    summary,
    amount: totals.totalAmount,
    now,
  });
  await batch.commit();

  return deliveryPayload(deliveryRef.id, {
    ...delivery,
    driverId,
    createdAt: new Date(),
  });
});

exports.linkCustomerByPhone = onCall(callableOptions, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in as customer first.");
  }

  const userRef = db.collection("users").doc(request.auth.uid);
  const userSnap = await userRef.get();
  const user = userSnap.data();
  const action = String(request.data.action || "link");
  if (action !== "link" && action !== "refresh") {
    const customerCtx = await requireCustomer(request.auth);
    const shopId = cleanText(request.data.shopId, "Shop id");
    const customerId = cleanText(request.data.customerId, "Customer id");
    await requireLinkedCustomer(customerCtx.uid, shopId, customerId);
    const orderRef = request.data.orderId
      ? db.collection("shops").doc(shopId).collection("orders").doc(request.data.orderId)
      : db.collection("shops").doc(shopId).collection("orders").doc();
    const now = admin.firestore.FieldValue.serverTimestamp();

    if (action === "createOrder") {
      const normalQty = Math.max(0, Number(request.data.normalQty) || 0);
      const coolQty = Math.max(0, Number(request.data.coolQty) || 0);
      const customerNote = String(request.data.customerNote || "").trim();
      if (normalQty + coolQty <= 0 && !customerNote) {
        throw new HttpsError("invalid-argument", "Add at least one item.");
      }
      const orderData = {
        shopId,
        customerId,
        placedByAppUserId: customerCtx.uid,
        normalQty,
        coolQty,
        status: "pending",
        customerNote,
        createdAt: now,
        updatedAt: now,
      };
      const batch = db.batch();
      batch.set(orderRef, orderData);
      appendOrderNotification({
        batch,
        shopId,
        type: "orderPlaced",
        audience: "admin",
        title: "New water request",
        body: "A customer placed a new water request. Review it in Orders.",
        customerId,
        orderId: orderRef.id,
        now,
      });
      await batch.commit();
    } else {
      const orderSnap = await orderRef.get();
      const order = orderSnap.data();
      if (!order || order.placedByAppUserId !== customerCtx.uid ||
          order.status !== "pending") {
        throw new HttpsError("failed-precondition", "Only pending requests can be changed.");
      }
      if (action === "cancelOrder") {
        await orderRef.set({
          status: "cancelled",
          adminResponse: "Cancelled by customer",
          respondedAt: now,
          updatedAt: now,
        }, { merge: true });
      } else if (action === "updateOrder") {
        const normalQty = Math.max(0, Number(request.data.normalQty) || 0);
        const coolQty = Math.max(0, Number(request.data.coolQty) || 0);
        const customerNote = String(request.data.customerNote || "").trim();
        if (normalQty + coolQty <= 0 && !customerNote) {
          throw new HttpsError("invalid-argument", "Add at least one item.");
        }
        await orderRef.set({
          normalQty,
          coolQty,
          customerNote,
          updatedAt: now,
        }, { merge: true });
      } else {
        throw new HttpsError("invalid-argument", "Unsupported customer action.");
      }
    }
    return { links: await customerPortalLinks(customerCtx.uid) };
  }

  if (action === "refresh") {
    const customerCtx = await requireCustomer(request.auth);
    return { links: await customerPortalLinks(customerCtx.uid) };
  }

  if (user && user.role && user.role !== "customer") {
    throw new HttpsError("permission-denied", "Customer access required.");
  }

  const authenticatedPhone = normalizeAuthPhone(request.auth.token.phone_number);
  const requestedPhone = normalizePhone(request.data.phone);
  if (requestedPhone !== authenticatedPhone) {
    throw new HttpsError("permission-denied", "Mobile number mismatch.");
  }
  const savedPhone = user ? normalizePhone(user.normalizedPhone || user.phone) : "";
  if (savedPhone && authenticatedPhone !== savedPhone) {
    throw new HttpsError("permission-denied", "Mobile number mismatch.");
  }
  const authPhone = authenticatedPhone;

  const matches = [];
  const customerSnaps = await db
    .collectionGroup("customers")
    .where("normalizedPhone", "==", authPhone)
    .get();
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (const customerSnap of customerSnaps.docs) {
    const customer = customerSnap.data();
    if (!customer || customer.active === false) continue;
    const shopRef = customerSnap.ref.parent.parent;
    if (!shopRef) continue;

    const shopSnap = await shopRef.get();
    const shop = shopSnap.data();
    if (!shop) continue;

    const customerId = customerSnap.id;
    const shopId = shopSnap.id;
    await db
      .collection("customerShopLinks")
      .doc(`${request.auth.uid}_${shopId}_${customerId}`)
      .set({
        uid: request.auth.uid,
        shopId,
        customerId,
        normalizedPhone: authPhone,
        active: true,
        createdAt: now,
        updatedAt: now,
      }, { merge: true });

    matches.push({
      shop: shopPayload(shopId, shop),
      customer: customerPayload(customerId, customer),
    });
  }

  await userRef.set({
    role: "customer",
    name: matches[0]?.customer?.name || "Customer",
    email: user?.email || "",
    phone: authPhone,
    normalizedPhone: authPhone,
    businessName: "",
    customerProfileComplete: matches.length > 0,
    active: true,
    createdAt: user?.createdAt || now,
    updatedAt: now,
  }, { merge: true });

  await db.collection("appCustomers").doc(request.auth.uid).set({
    phone: authPhone,
    normalizedPhone: authPhone,
    createdAt: now,
    updatedAt: now,
  }, { merge: true });

  if (matches.length === 0) {
    return { matches: [] };
  }

  const first = matches[0];
  await db.collection("appCustomers").doc(request.auth.uid).set({
    name: first.customer.name,
    phone: authPhone,
    normalizedPhone: authPhone,
    address: first.customer.address,
    email: first.customer.email,
    place: first.customer.place,
    linkedCrmCustomerId: first.customer.id,
    onboardingComplete: true,
    updatedAt: now,
  }, { merge: true });
  await userRef.set({
    name: first.customer.name,
    customerProfileComplete: true,
    updatedAt: now,
  }, { merge: true });

  return {
    matches,
    links: await customerPortalLinks(request.auth.uid),
    profile: {
      name: first.customer.name,
      phone: authPhone,
      address: first.customer.address,
      email: first.customer.email,
      place: first.customer.place,
      linkedCrmCustomerId: first.customer.id,
      latitude: first.shop.latitude || null,
      longitude: first.shop.longitude || null,
      onboardingComplete: true,
    },
  };
});

exports.respondToCustomerOrder = onCall(callableOptions, async (request) => {
  const adminCtx = await requireAdmin(request.auth);
  const orderId = cleanText(request.data.orderId, "Order id");
  const status = cleanText(request.data.status, "Status");
  if (!["accepted", "rejected"].includes(status)) {
    throw new HttpsError("invalid-argument", "Unsupported order status.");
  }
  const adminResponse = String(request.data.adminResponse || "").trim();
  const orderRef = db
    .collection("shops")
    .doc(adminCtx.shopId)
    .collection("orders")
    .doc(orderId);
  const orderSnap = await orderRef.get();
  const order = orderSnap.data();
  if (!order || order.status !== "pending") {
    throw new HttpsError("failed-precondition", "Pending request not found.");
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();
  batch.set(orderRef, {
    status,
    adminResponse,
    respondedAt: now,
    updatedAt: now,
  }, { merge: true });
  appendOrderNotification({
    batch,
    shopId: adminCtx.shopId,
    type: status === "accepted" ? "orderAccepted" : "orderRejected",
    audience: "customer",
    title: status === "accepted" ? "Request accepted" : "Request declined",
    body: status === "accepted"
      ? "Your water request was accepted. A driver will deliver soon."
      : `Your water request was declined.${adminResponse ? ` Reason: ${adminResponse}` : ""}`,
    customerId: order.customerId,
    orderId,
    now,
  });
  if (status === "accepted") {
    appendOrderNotification({
      batch,
      shopId: adminCtx.shopId,
      type: "orderAccepted",
      audience: "driver",
      title: "New delivery task",
      body: "An accepted customer request is ready for delivery.",
      customerId: order.customerId,
      orderId,
      now,
    });
  }
  await batch.commit();
  return orderPayload(orderId, {
    ...order,
    status,
    adminResponse,
    respondedAt: new Date(),
  });
});

exports.getCustomerPortalData = onCall(callableOptions, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in as customer first.");
  }

  const userSnap = await db.collection("users").doc(request.auth.uid).get();
  const user = userSnap.data();
  if (!user || user.role !== "customer") {
    throw new HttpsError("permission-denied", "Customer access required.");
  }

  return { links: await customerPortalLinks(request.auth.uid) };
});
