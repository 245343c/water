"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

const db = admin.firestore();
const callableOptions = {
  invoker: "public",
  region: "asia-south1",
  maxInstances: 3,
  enforceAppCheck: true,
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

const SUBSCRIPTION_PLANS = {
  starter: {
    id: "starter",
    name: "Starter",
    monthlyPriceInr: 499,
    annualPriceInr: 4999,
    customerLimit: 150,
    driverLimit: 1,
  },
  standard: {
    id: "standard",
    name: "Standard",
    monthlyPriceInr: 999,
    annualPriceInr: 9999,
    customerLimit: 500,
    driverLimit: 5,
  },
  premium: {
    id: "premium",
    name: "Premium",
    monthlyPriceInr: 1999,
    annualPriceInr: 19999,
    customerLimit: 1500,
    driverLimit: 15,
  },
};

const SUBSCRIPTION_TRIAL_DAYS = 30;
const SUBSCRIPTION_GRACE_DAYS = 7;

function addMonths(date, months) {
  const next = new Date(date.getTime());
  next.setMonth(next.getMonth() + months);
  return next;
}

function timestampFromDate(date) {
  return admin.firestore.Timestamp.fromDate(date);
}

function readDate(value) {
  if (!value) return null;
  if (value.toDate) return value.toDate();
  if (value instanceof Date) return value;
  const parsed = new Date(String(value));
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

async function ensureShopSubscriptionFresh(shopRef, shop) {
  if (!shop) return shop;
  const now = new Date();
  const updates = {};
  let status = shop.subscriptionStatus || "trial";
  let trialEndsAt = readDate(shop.trialEndsAt);
  const createdAt = readDate(shop.createdAt);

  if (!trialEndsAt) {
    const base = createdAt || now;
    trialEndsAt = new Date(
      base.getTime() + SUBSCRIPTION_TRIAL_DAYS * 24 * 60 * 60 * 1000,
    );
    updates.trialEndsAt = timestampFromDate(trialEndsAt);
    if (!shop.subscriptionStatus) {
      updates.subscriptionStatus = "trial";
      status = "trial";
    }
  }

  if (!shop.planId) {
    updates.planId = "standard";
  }
  if (!shop.billingCycle) {
    updates.billingCycle = "monthly";
  }

  const graceEndsAt = readDate(shop.graceEndsAt)
    || (trialEndsAt
      ? new Date(
        trialEndsAt.getTime() + SUBSCRIPTION_GRACE_DAYS * 24 * 60 * 60 * 1000,
      )
      : null);

  if (status === "trial" && trialEndsAt && now > trialEndsAt) {
    if (graceEndsAt && now <= graceEndsAt) {
      status = "grace";
      updates.subscriptionStatus = "grace";
      updates.graceEndsAt = timestampFromDate(graceEndsAt);
    } else {
      status = "expired";
      updates.subscriptionStatus = "expired";
    }
  }

  if (status === "grace") {
    const graceEnd = readDate(shop.graceEndsAt) || graceEndsAt;
    if (graceEnd && now > graceEnd) {
      status = "expired";
      updates.subscriptionStatus = "expired";
    }
  }

  if (status === "active") {
    const renewsAt = readDate(shop.currentPeriodEndsAt);
    if (renewsAt && now > renewsAt) {
      const activeGraceEnd = readDate(shop.graceEndsAt)
        || new Date(
          renewsAt.getTime() + SUBSCRIPTION_GRACE_DAYS * 24 * 60 * 60 * 1000,
        );
      if (now <= activeGraceEnd) {
        status = "grace";
        updates.subscriptionStatus = "grace";
        if (!shop.graceEndsAt) {
          updates.graceEndsAt = timestampFromDate(activeGraceEnd);
        }
      } else {
        status = "expired";
        updates.subscriptionStatus = "expired";
      }
    }
  }

  if (Object.keys(updates).length > 0) {
    updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    await shopRef.set(updates, { merge: true });
    return { ...shop, ...updates, subscriptionStatus: status };
  }

  return { ...shop, subscriptionStatus: status };
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

const blockedEmailDomains = new Set([
  "example.com",
  "example.org",
  "example.net",
  "test.com",
  "test.local",
  "waterapp.local",
  "mailinator.com",
  "tempmail.com",
  "temp-mail.org",
  "10minutemail.com",
  "guerrillamail.com",
  "yopmail.com",
]);

function isValidPublicEmail(email) {
  if (!/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i.test(email)) {
    return false;
  }
  const parts = email.split("@");
  if (parts.length !== 2) return false;
  const [local, domain] = parts;
  if (local.startsWith(".") || local.endsWith(".") || local.includes("..")) {
    return false;
  }
  if (
    domain.startsWith("-") ||
    domain.endsWith("-") ||
    domain.includes("..") ||
    blockedEmailDomains.has(domain)
  ) {
    return false;
  }
  return true;
}

function cleanEmail(value) {
  const email = cleanText(value, "Email").toLowerCase();
  if (!isValidPublicEmail(email)) {
    throw new HttpsError("invalid-argument", "Enter a valid real email.");
  }
  return email;
}

function cleanOptionalEmail(value) {
  const email = String(value || "").trim().toLowerCase();
  if (!email) return "";
  if (!isValidPublicEmail(email)) {
    throw new HttpsError("invalid-argument", "Enter a valid real email.");
  }
  return email;
}

function normalizePhone(value) {
  const digits = String(value || "").replace(/\D/g, "");
  if (!/^[6-9]\d{9}$/.test(digits)) {
    throw new HttpsError(
      "invalid-argument",
      "Enter a valid 10-digit mobile number.",
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

function adminAuthEmail(phoneDigits) {
  return `admin_${phoneDigits}@waterapp.local`;
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

async function assertAdminSignupAvailable({ email, phone, allowUid = null }) {
  const normalizedPhone = normalizePhone(phone);
  const authEmail = adminAuthEmail(normalizedPhone);
  const emailsToCheck = email ? [email, authEmail] : [authEmail];
  for (const candidateEmail of emailsToCheck) {
    try {
      const user = await admin.auth().getUserByEmail(candidateEmail);
      if (!allowUid || user.uid !== allowUid) {
        throw new HttpsError(
          "already-exists",
          candidateEmail === authEmail
            ? "Mobile number already has an account."
            : "Email already has an account.",
        );
      }
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      if (error.code !== "auth/user-not-found") throw error;
    }
  }
  try {
    const user = await admin.auth().getUserByPhoneNumber(`+91${normalizedPhone}`);
    if (!allowUid || user.uid !== allowUid) {
      throw new HttpsError("already-exists", "Mobile number already has an account.");
    }
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    if (error.code !== "auth/user-not-found") throw error;
  }

  const existingPhone = await db
    .collection("users")
    .where("normalizedPhone", "==", normalizedPhone)
    .limit(1)
    .get();
  if (!existingPhone.empty) {
    throw new HttpsError("already-exists", "Mobile number already has an account.");
  }
  const legacyPhone = await db
    .collection("users")
    .where("phone", "==", normalizedPhone)
    .limit(1)
    .get();
  if (!legacyPhone.empty) {
    throw new HttpsError("already-exists", "Mobile number already has an account.");
  }
  if (email) {
    const existingEmail = await db
      .collection("users")
      .where("email", "==", email)
      .limit(1)
      .get();
    if (!existingEmail.empty) {
      throw new HttpsError("already-exists", "Email already has an account.");
    }
  }
  return normalizedPhone;
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

function cleanFcmToken(value) {
  const token = String(value || "").trim();
  if (token.length < 20 || token.length > 4096) {
    throw new HttpsError("invalid-argument", "A valid FCM token is required.");
  }
  return token;
}

function tokenDocId(token) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function cleanPlatform(value) {
  const platform = String(value || "").trim().toLowerCase();
  return ["android", "ios", "web", "macos", "windows"].includes(platform)
    ? platform
    : "unknown";
}

function pushData(data) {
  const result = {};
  for (const [key, value] of Object.entries(data || {})) {
    if (value === undefined || value === null) continue;
    result[key] = String(value);
  }
  return result;
}

async function tokenDocsForUser(uid) {
  const snap = await db
    .collection("users")
    .doc(uid)
    .collection("fcmTokens")
    .where("active", "==", true)
    .get();
  return snap.docs.map((doc) => ({ ref: doc.ref, token: doc.data().token }));
}

async function userIdsForPushAudience({ shopId, audience, customerId, driverId }) {
  if (audience === "admin" || audience === "driver") {
    const snap = await db
      .collection("users")
      .where("shopId", "==", shopId)
      .where("role", "==", audience)
      .get();
    return snap.docs
      .filter((doc) => doc.data().active !== false)
      .filter((doc) => {
        if (audience !== "driver" || !driverId) return true;
        return doc.data().driverId === driverId;
      })
      .map((doc) => doc.id);
  }

  if (audience === "customer" && customerId) {
    const snap = await db
      .collection("customerShopLinks")
      .where("shopId", "==", shopId)
      .where("customerId", "==", customerId)
      .where("active", "==", true)
      .get();
    return snap.docs
      .map((doc) => doc.data().uid)
      .filter((uid) => !!uid);
  }

  return [];
}

async function sendPushToAudience({
  shopId,
  audience,
  title,
  body,
  customerId,
  driverId,
  data,
}) {
  const userIds = await userIdsForPushAudience({
    shopId,
    audience,
    customerId,
    driverId,
  });
  if (userIds.length === 0) return;

  const tokenDocs = [];
  for (const uid of userIds) {
    tokenDocs.push(...await tokenDocsForUser(uid));
  }
  const unique = new Map();
  for (const item of tokenDocs) {
    if (item.token) unique.set(item.token, item.ref);
  }
  const tokens = [...unique.keys()];
  if (tokens.length === 0) return;

  for (let i = 0; i < tokens.length; i += 500) {
    const chunk = tokens.slice(i, i + 500);
    const message = {
      tokens: chunk,
      notification: { title, body },
      data: pushData({
        shopId,
        audience,
        customerId,
        ...data,
      }),
      android: {
        priority: "high",
        notification: {
          channelId: "deliveries",
          icon: "ic_launcher",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    };
    const response = await admin.messaging().sendEachForMulticast(message);
    const deletes = [];
    response.responses.forEach((item, index) => {
      if (item.success) return;
      const code = item.error?.code || "";
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        const ref = unique.get(chunk[index]);
        if (ref) deletes.push(ref.delete());
      }
    });
    if (deletes.length > 0) await Promise.all(deletes);
  }
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
  const fulfilledAt = data.fulfilledAt && data.fulfilledAt.toDate
    ? data.fulfilledAt.toDate()
    : data.fulfilledAt;
  return {
    id: orderId,
    customerId: data.customerId || "",
    shopId: data.shopId || "",
    placedByAppUserId: data.placedByAppUserId || "",
    normalQty: data.normalQty || 0,
    coolQty: data.coolQty || 0,
    status: data.status || "pending",
    source: data.source || "customerApp",
    paymentMode: data.paymentMode || "billLater",
    customerNote: data.customerNote || "",
    adminResponse: data.adminResponse || "",
    lineItems: data.lineItems || [],
    walkInContact: data.walkInContact || null,
    createdAt: createdAt instanceof Date ? createdAt.toISOString() : "",
    respondedAt: respondedAt instanceof Date ? respondedAt.toISOString() : "",
    driverAcceptedAt: driverAcceptedAt instanceof Date
      ? driverAcceptedAt.toISOString()
      : "",
    deliveryStartedAt: deliveryStartedAt instanceof Date
      ? deliveryStartedAt.toISOString()
      : "",
    fulfilledAt: fulfilledAt instanceof Date ? fulfilledAt.toISOString() : "",
    fulfilledBy: data.fulfilledBy || "",
    adminDispatchNote: data.adminDispatchNote || "",
    collectionStatus: data.collectionStatus || "",
    collectedAmount: data.collectedAmount || 0,
    collectionMethod: data.collectionMethod || "",
    collectionRecordedBy: data.collectionRecordedBy || "",
    instantOutcome: data.instantOutcome || "",
    driverId: data.driverId || "",
  };
}

function cleanCollectionStatus(value) {
  const status = String(value || "").trim();
  if (["collected", "pending", "waived"].includes(status)) return status;
  throw new HttpsError("invalid-argument", "Invalid collection status.");
}

function collectionStatusLabel(status, amount, method) {
  if (status === "collected") {
    const methodLabel = method === "upi" ? "UPI" : "Cash";
    return amount > 0
      ? `Payment received · ${methodLabel} ₹${amount}`
      : "Payment received";
  }
  if (status === "pending") {
    return "Delivered · payment pending (customer will pay admin)";
  }
  return "Delivered · pay later";
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

const CAN_PRODUCT_ID = "__water_cans__";
const CHANNEL_PRODUCT_ID = "__delivery_channels__";

function cleanOrderLineItems(value) {
  if (!Array.isArray(value) || value.length === 0) {
    throw new HttpsError("invalid-argument", "Add at least one product.");
  }

  return value.map((raw) => {
    const item = raw || {};
    const productId = cleanText(item.productId, "Product id");
    const variantId = cleanText(item.variantId, "Variant id");
    const label = cleanText(item.label, "Label");
    const quantity = Number(item.quantity);
    if (!Number.isInteger(quantity) || quantity <= 0) {
      throw new HttpsError("invalid-argument", "Invalid quantity.");
    }
    return { productId, variantId, label, quantity };
  });
}

function orderLineTotals(lineItems) {
  return lineItems.reduce(
    (totals, line) => {
      if (line.productId === CAN_PRODUCT_ID && line.variantId === "normal") {
        totals.normalQty += line.quantity;
      }
      if (line.productId === CAN_PRODUCT_ID && line.variantId === "cool") {
        totals.coolQty += line.quantity;
      }
      return totals;
    },
    { normalQty: 0, coolQty: 0 },
  );
}

async function walkInProductPrices(shopId) {
  const shopSnap = await db.collection("shops").doc(shopId).get();
  const shop = shopSnap.data() || {};
  const prices = [
    {
      productId: CAN_PRODUCT_ID,
      variantId: "normal",
      unitPrice: Number(shop.normalPrice) || 20,
      enabled: true,
    },
    {
      productId: CAN_PRODUCT_ID,
      variantId: "cool",
      unitPrice: Number(shop.coolPrice) || 30,
      enabled: true,
    },
    {
      productId: CHANNEL_PRODUCT_ID,
      variantId: "lorryLiters",
      unitPrice: Number(shop.lorryLiterPrice) || 0,
      enabled: true,
    },
    {
      productId: CHANNEL_PRODUCT_ID,
      variantId: "fullLorry",
      unitPrice: Number(shop.fullLorryPrice) || 0,
      enabled: true,
    },
    {
      productId: CHANNEL_PRODUCT_ID,
      variantId: "autoLiters",
      unitPrice: Number(shop.autoLiterPrice) || 0,
      enabled: true,
    },
    {
      productId: CHANNEL_PRODUCT_ID,
      variantId: "autoCans",
      unitPrice: Number(shop.autoCanPrice) || 0,
      enabled: true,
    },
  ];

  const productsSnap = await db
    .collection("shops")
    .doc(shopId)
    .collection("products")
    .where("active", "==", true)
    .get();
  for (const doc of productsSnap.docs) {
    const product = doc.data();
    for (const variant of asVariantList(product.variants)) {
      prices.push({
        productId: doc.id,
        variantId: String(variant.id || ""),
        unitPrice: Number(variant.price) || 0,
        enabled: true,
      });
    }
  }
  return prices;
}

function asVariantList(variants) {
  if (Array.isArray(variants)) return variants;
  if (variants && typeof variants === "object") {
    return Object.values(variants);
  }
  return [];
}

function dispatchItemsSummary(lineItems) {
  return lineItems
    .filter((line) => line.quantity > 0)
    .map((line) => `${line.quantity} ${line.label}`)
    .join(" · ");
}

function shopPayload(shopId, data) {
  const trialEndsAt = readDate(data.trialEndsAt);
  const graceEndsAt = readDate(data.graceEndsAt);
  const currentPeriodEndsAt = readDate(data.currentPeriodEndsAt);
  const subscriptionStartedAt = readDate(data.subscriptionStartedAt);
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
    graceEndsAt: graceEndsAt instanceof Date ? graceEndsAt.toISOString() : "",
    currentPeriodEndsAt: currentPeriodEndsAt instanceof Date
      ? currentPeriodEndsAt.toISOString()
      : "",
    subscriptionStartedAt: subscriptionStartedAt instanceof Date
      ? subscriptionStartedAt.toISOString()
      : "",
    planId: data.planId || "standard",
    billingCycle: data.billingCycle || "monthly",
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
      variantId: item.variantId ? String(item.variantId).trim() : null,
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

function channelFallbackPrice(shop, variantId) {
  const key = String(variantId || "").trim();
  const fallbackByVariant = {
    lorryLiters: Number(shop.lorryLiterPrice) || 0,
    fullLorry: Number(shop.fullLorryPrice) || 0,
    autoLiters: Number(shop.autoLiterPrice) || 0,
    autoCans: Number(shop.autoCanPrice) || 0,
  };
  return fallbackByVariant[key] ?? 0;
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
      if (line.productId === CHANNEL_PRODUCT_ID) {
        if (!line.variantId) {
          throw new HttpsError(
            "invalid-argument",
            "Delivery channel variant is required.",
          );
        }
        unitPrice = customerPrice(
          customer,
          CHANNEL_PRODUCT_ID,
          line.variantId,
          channelFallbackPrice(shop, line.variantId),
        );
        return {
          ...line,
          unitPrice,
          lineTotal: line.quantity * unitPrice,
        };
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
          (!line.variantId || price.variantId === line.variantId) &&
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
  driverId,
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
      driverId: driverId || null,
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

exports.checkAdminSignupAvailability = onCall(callableOptions, async (request) => {
  const email = cleanOptionalEmail(request.data.email);
  const phone = cleanText(request.data.phone, "Phone", 10);
  const normalizedPhone = await assertAdminSignupAvailable({ email, phone });
  return { ok: true, normalizedPhone };
});

exports.completeAdminRegistration = onCall(callableOptions, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Verify mobile OTP first.");
  }
  const authPhone = normalizeAuthPhone(request.auth.token.phone_number);
  const email = cleanOptionalEmail(request.data.email);
  const normalizedPhone = normalizePhone(request.data.phone);
  const expectedAuthEmail = email || adminAuthEmail(normalizedPhone);
  if (authPhone !== normalizedPhone) {
    throw new HttpsError(
      "permission-denied",
      "Verified mobile number does not match this signup.",
    );
  }
  await assertAdminSignupAvailable({
    email,
    phone: normalizedPhone,
    allowUid: request.auth.uid,
  });

  const ownerName = cleanText(request.data.ownerName, "Owner name");
  const businessName = cleanText(request.data.businessName, "Business name");
  const address = cleanText(request.data.address, "Shop address", 8);
  const normalPrice = Number(request.data.normalPrice);
  const coolPrice = Number(request.data.coolPrice);
  const homeDeliveryAvailable = request.data.homeDeliveryAvailable === true;
  const uid = request.auth.uid;
  const authUser = await admin.auth().getUser(uid);
  if (authUser.email && authUser.email.toLowerCase() !== expectedAuthEmail) {
    throw new HttpsError(
      "failed-precondition",
      "Verified account email does not match this signup.",
    );
  }
  if (!authUser.email) {
    throw new HttpsError(
      "failed-precondition",
      "Set login password before completing signup.",
    );
  }

  const shopRef = db.collection("shops").doc();
  const userRef = db.collection("users").doc(uid);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const authPhoneNumber = request.auth.token.phone_number || `+91${normalizedPhone}`;

  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    if (userSnap.exists) {
      throw new HttpsError("already-exists", "This account is already registered.");
    }
    tx.set(userRef, {
      role: "admin",
      name: ownerName,
      email,
      authEmail: expectedAuthEmail,
      phone: normalizedPhone,
      normalizedPhone,
      authPhoneNumber,
      businessName,
      shopId: shopRef.id,
      customerProfileComplete: true,
      pricingSetupComplete: false,
      active: true,
      phoneVerified: true,
      emailVerified: authUser.emailVerified === true,
      approvalStatus: "active",
      createdAt: now,
      updatedAt: now,
    });
    tx.set(shopRef, {
      ownerUid: uid,
      name: businessName,
      address,
      phone: normalizedPhone,
      normalizedPhone,
      email,
      authEmail: expectedAuthEmail,
      normalPrice: Number.isFinite(normalPrice) ? normalPrice : 20,
      coolPrice: Number.isFinite(coolPrice) ? coolPrice : 30,
      homeDeliveryAvailable,
      subscriptionStatus: "trial",
      trialEndsAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + SUBSCRIPTION_TRIAL_DAYS * 24 * 60 * 60 * 1000),
      ),
      planId: "standard",
      billingCycle: "monthly",
      active: true,
      isListed: homeDeliveryAvailable,
      approvalStatus: "active",
      createdAt: now,
      updatedAt: now,
    });
  });

  await admin.auth().setCustomUserClaims(uid, {
    role: "admin",
    shopId: shopRef.id,
  });

  return {
    user: {
      id: uid,
      ownerName,
      email,
      phone: normalizedPhone,
      businessName,
      role: "admin",
      pricingSetupComplete: false,
    },
    shopId: shopRef.id,
  };
});

exports.registerFcmToken = onCall(callableOptions, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  const token = cleanFcmToken(request.data.token);
  const platform = cleanPlatform(request.data.platform);
  const userSnap = await db.collection("users").doc(request.auth.uid).get();
  const user = userSnap.data();
  if (!user || user.active === false) {
    throw new HttpsError("permission-denied", "Active user account required.");
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const docId = tokenDocId(token);
  const staleSnap = await db
    .collectionGroup("fcmTokens")
    .where("tokenHash", "==", docId)
    .where("active", "==", true)
    .get();
  const batch = db.batch();
  staleSnap.docs.forEach((doc) => {
    if (doc.ref.parent.parent?.id !== request.auth.uid) {
      batch.set(doc.ref, { active: false, updatedAt: now }, { merge: true });
    }
  });
  batch.set(userSnap.ref.collection("fcmTokens").doc(docId), {
    token,
    tokenHash: docId,
    platform,
    role: user.role || "",
    shopId: user.shopId || "",
    driverId: user.driverId || "",
    active: true,
    updatedAt: now,
    createdAt: now,
  }, { merge: true });
  batch.set(userSnap.ref, {
    lastFcmTokenAt: now,
    updatedAt: now,
  }, { merge: true });
  await batch.commit();

  return { ok: true };
});

exports.unregisterFcmToken = onCall(callableOptions, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  const token = cleanFcmToken(request.data.token);
  await db
    .collection("users")
    .doc(request.auth.uid)
    .collection("fcmTokens")
    .doc(tokenDocId(token))
    .set({
      active: false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  return { ok: true };
});

exports.resolveStaffLogin = onCall(callableOptions, async (request) => {
  const normalizedPhone = normalizePhone(request.data.phone);
  const snap = await db
    .collection("users")
    .where("normalizedPhone", "==", normalizedPhone)
    .limit(5)
    .get();

  const roleOrder = { admin: 0, driver: 1 };
  const emails = snap.docs
    .map((doc) => doc.data())
    .filter((user) => ["admin", "driver"].includes(user.role))
    .filter((user) => user.active !== false)
    .sort((a, b) => roleOrder[a.role] - roleOrder[b.role])
    .map((user) => {
      if (user.authEmail) return user.authEmail;
      if (user.role === "admin" && user.email) return user.email;
      if (user.role === "admin") return adminAuthEmail(normalizedPhone);
      return driverAuthEmail(normalizedPhone);
    })
    .filter((email, index, all) => email && all.indexOf(email) === index);

  return { emails };
});

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
  if (lines.length > 0 && customer.billingMode === "instantDispatch") {
    throw new HttpsError(
      "failed-precondition",
      "Quick delivery customers cannot receive regular deliveries.",
    );
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
  await Promise.all([
    sendPushToAudience({
      shopId: staffCtx.shopId,
      audience: "admin",
      title: "Delivery recorded",
      body: `${driverName} delivered ${summary} to ${customer.name || "Customer"}. Bill Rs.${Math.round(totals.totalAmount)} updated.`,
      customerId,
      data: {
        type: "deliveryRecorded",
        deliveryId: deliveryRef.id,
        driverId,
      },
    }),
    sendPushToAudience({
      shopId: staffCtx.shopId,
      audience: "customer",
      title: "Water delivered today",
      body: `${summary} delivered to your address. Amount Rs.${Math.round(totals.totalAmount)} added to your account.`,
      customerId,
      data: {
        type: "deliveryRecorded",
        deliveryId: deliveryRef.id,
        driverId,
      },
    }),
  ]);

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
  await sendPushToAudience({
    shopId: adminCtx.shopId,
    audience: "customer",
    title: status === "accepted" ? "Request accepted" : "Request declined",
    body: status === "accepted"
      ? "Your water request was accepted. A driver will deliver soon."
      : `Your water request was declined.${adminResponse ? ` Reason: ${adminResponse}` : ""}`,
    customerId: order.customerId,
    data: {
      type: status === "accepted" ? "orderAccepted" : "orderRejected",
      orderId,
    },
  });
  if (status === "accepted") {
    await sendPushToAudience({
      shopId: adminCtx.shopId,
      audience: "driver",
      title: "New delivery task",
      body: "An accepted customer request is ready for delivery.",
      customerId: order.customerId,
      data: {
        type: "orderAccepted",
        orderId,
      },
    });
  }
  return orderPayload(orderId, {
    ...order,
    status,
    adminResponse,
    respondedAt: new Date(),
  });
});

exports.createWalkInDispatch = onCall(callableOptions, async (request) => {
  try {
    return await createWalkInDispatchHandler(request);
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("createWalkInDispatch failed", error);
    throw new HttpsError(
      "internal",
      error.message || "Instant delivery could not be saved.",
    );
  }
});

async function createWalkInDispatchHandler(request) {
  const adminCtx = await requireAdmin(request.auth);
  const callerName = cleanText(request.data.callerName, "Caller name");
  const callerPhone = normalizePhone(request.data.callerPhone);
  const callerAddress = cleanText(request.data.callerAddress, "Delivery address");
  const callerPlace = String(request.data.callerPlace || "").trim();
  const customerNote = String(request.data.note || "").trim();
  const lineItems = cleanOrderLineItems(request.data.lineItems);
  const totals = orderLineTotals(lineItems);
  const productPrices = await walkInProductPrices(adminCtx.shopId);
  const sendToDriver = request.data.sendToDriver !== false;
  let assignedDriverId = null;
  if (sendToDriver) {
    assignedDriverId = cleanText(request.data.driverId, "Driver");
    const { driver } = await getDriverForAdmin(adminCtx, assignedDriverId);
    if (driver.active === false) {
      throw new HttpsError("failed-precondition", "Selected driver is inactive.");
    }
  }

  const shopRef = db.collection("shops").doc(adminCtx.shopId);
  const customerRef = shopRef.collection("customers").doc();
  const orderRef = shopRef.collection("orders").doc();
  const now = admin.firestore.FieldValue.serverTimestamp();

  const walkInContact = {
    name: callerName,
    phone: callerPhone,
    address: callerAddress,
    place: callerPlace,
  };

  const customer = {
    name: callerName,
    phone: callerPhone,
    normalizedPhone: callerPhone,
    email: "",
    place: callerPlace,
    address: callerAddress,
    routeId: null,
    paymentFrequency: "Monthly",
    billingMode: "instantDispatch",
    productPrices,
    appUserId: null,
    active: true,
    createdAt: now,
    updatedAt: now,
  };

  const order = {
    shopId: adminCtx.shopId,
    customerId: customerRef.id,
    normalQty: totals.normalQty,
    coolQty: totals.coolQty,
    status: sendToDriver ? "accepted" : "rejected",
    source: "phoneCall",
    paymentMode: "collectAtDoor",
    customerNote,
    adminResponse: sendToDriver
      ? "Instant delivery — driver collects payment at door."
      : "No stock — informed customer.",
    lineItems,
    walkInContact,
    instantOutcome: sendToDriver ? "sent" : "noStock",
    respondedAt: now,
    createdAt: now,
    updatedAt: now,
    fulfilledAt: null,
    ...(assignedDriverId ? { driverId: assignedDriverId } : {}),
  };

  const batch = db.batch();
  batch.set(customerRef, customer);
  batch.set(orderRef, order);
  if (sendToDriver) {
    appendOrderNotification({
      batch,
      shopId: adminCtx.shopId,
      type: "orderAccepted",
      audience: "driver",
      title: "Instant delivery",
      body: `${callerName} · ${dispatchItemsSummary(lineItems)}`,
      customerId: customerRef.id,
      orderId: orderRef.id,
      driverId: assignedDriverId,
      now,
    });
  } else {
    appendOrderNotification({
      batch,
      shopId: adminCtx.shopId,
      type: "orderRejected",
      audience: "admin",
      title: "Instant — no stock",
      body: `${callerName} · ${dispatchItemsSummary(lineItems)} — not sent to driver`,
      customerId: customerRef.id,
      orderId: orderRef.id,
      now,
    });
  }
  await batch.commit();
  if (sendToDriver) {
    await sendPushToAudience({
      shopId: adminCtx.shopId,
      audience: "driver",
      title: "Instant delivery",
      body: `${callerName} - ${dispatchItemsSummary(lineItems)}`,
      customerId: customerRef.id,
      driverId: assignedDriverId,
      data: {
        type: "orderAccepted",
        orderId: orderRef.id,
      },
    });
  } else {
    await sendPushToAudience({
      shopId: adminCtx.shopId,
      audience: "admin",
      title: "Instant - no stock",
      body: `${callerName} - ${dispatchItemsSummary(lineItems)} - not sent to driver`,
      customerId: customerRef.id,
      data: {
        type: "orderRejected",
        orderId: orderRef.id,
      },
    });
  }

  return {
    order: orderPayload(orderRef.id, {
      ...order,
      createdAt: new Date(),
      respondedAt: new Date(),
    }),
    customer: customerPayload(customerRef.id, customer),
  };
}

exports.fulfillDispatchOrder = onCall(callableOptions, async (request) => {
  const staffCtx = await requireShopStaff(request.auth, { allowDriver: true });
  const orderId = cleanText(request.data.orderId, "Order id");
  const orderRef = db
    .collection("shops")
    .doc(staffCtx.shopId)
    .collection("orders")
    .doc(orderId);
  const orderSnap = await orderRef.get();
  const order = orderSnap.data();
  if (!order || order.status !== "accepted" || order.fulfilledAt) {
    throw new HttpsError("failed-precondition", "Active instant delivery not found.");
  }
  if (order.source !== "phoneCall") {
    throw new HttpsError("failed-precondition", "Only instant dispatch orders use this flow.");
  }
  if (
    staffCtx.role === "driver" &&
    order.driverId &&
    order.driverId !== staffCtx.driverId
  ) {
    throw new HttpsError(
      "permission-denied",
      "This delivery is assigned to another driver.",
    );
  }

  const collectionStatus = cleanCollectionStatus(request.data.collectionStatus);
  const collectedAmount = collectionStatus === "collected"
    ? cleanAmount(request.data.collectedAmount)
    : 0;
  const collectionMethod = collectionStatus === "collected"
    ? cleanPaymentMethod(request.data.collectionMethod)
    : "";
  const customerId = order.customerId;
  const date = cleanDate(request.data.date, "Delivery date");
  const emptyNormalReturned = cleanEmptyCanCount(request.data.emptyNormalReturned);
  const emptyCoolReturned = cleanEmptyCanCount(request.data.emptyCoolReturned);
  let lines = Array.isArray(request.data.lines) ? request.data.lines : [];
  if (lines.length === 0) {
    throw new HttpsError("invalid-argument", "Add what was delivered.");
  }
  lines = cleanDeliveryLines(lines);

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

  lines = await applyCanonicalDeliveryPrices(staffCtx.shopId, customer, lines);
  const totals = deliveryTotals(lines);
  const now = admin.firestore.FieldValue.serverTimestamp();
  const fulfilledBy = staffCtx.role === "driver" ? "driver" : "admin";
  const collectionRecordedBy = fulfilledBy;
  const driverId = staffCtx.role === "driver"
    ? staffCtx.driverId
    : (request.data.driverId || null);
  const driverName = await resolveDriverName(
    staffCtx.shopId,
    driverId,
    request.data.driverName,
  );
  const callerName = order.walkInContact?.name || customer.name || "Customer";
  const summary = deliveryCansSummary(totals);

  const deliveryRef = db
    .collection("shops")
    .doc(staffCtx.shopId)
    .collection("deliveries")
    .doc();
  const monthlySummary = baseMonthlySummary(staffCtx.shopId, customerId, date);
  const delivery = {
    shopId: staffCtx.shopId,
    customerId,
    orderId,
    date: admin.firestore.Timestamp.fromDate(date),
    lines,
    emptyNormalReturned,
    emptyCoolReturned,
    normalQty: totals.normalQty,
    coolQty: totals.coolQty,
    bottleQty: totals.bottleQty,
    totalAmount: totals.totalAmount,
    driverId,
    createdAt: now,
    updatedAt: now,
    createdBy: staffCtx.uid,
  };

  const batch = db.batch();
  batch.set(deliveryRef, delivery);
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

  if (collectionStatus === "collected" && collectedAmount > 0) {
    const paymentRef = db
      .collection("shops")
      .doc(staffCtx.shopId)
      .collection("payments")
      .doc();
    const paymentSummary = baseMonthlySummary(staffCtx.shopId, customerId, date);
    const payment = {
      shopId: staffCtx.shopId,
      customerId,
      amount: collectedAmount,
      method: collectionMethod,
      notes: `Instant delivery ${orderId}`,
      date: admin.firestore.Timestamp.fromDate(date),
      createdAt: now,
      updatedAt: now,
      createdBy: staffCtx.uid,
    };
    batch.set(paymentRef, payment);
    batch.set(
      paymentSummary.ref,
      {
        ...paymentSummary.data,
        paymentCount: admin.firestore.FieldValue.increment(1),
        paymentAmount: admin.firestore.FieldValue.increment(collectedAmount),
      },
      { merge: true },
    );
  }

  batch.set(orderRef, {
    fulfilledAt: now,
    fulfilledBy,
    collectionStatus,
    collectedAmount: collectionStatus === "collected" ? collectedAmount : 0,
    collectionMethod: collectionStatus === "collected" ? collectionMethod : "",
    collectionRecordedBy,
    deliveryId: deliveryRef.id,
    updatedAt: now,
  }, { merge: true });

  appendDeliveryNotifications({
    batch,
    shopId: staffCtx.shopId,
    customerId,
    customerName: callerName,
    deliveryId: deliveryRef.id,
    driverId,
    driverName,
    summary,
    amount: totals.totalAmount,
    now,
  });
  appendOrderNotification({
    batch,
    shopId: staffCtx.shopId,
    type: collectionStatus === "pending"
      ? "dispatchPaymentPending"
      : "dispatchFulfilled",
    audience: "admin",
    title: collectionStatus === "pending"
      ? "Instant · payment pending"
      : "Instant · delivered",
    body: `${callerName} · ${summary} — ${collectionStatusLabel(
      collectionStatus,
      collectedAmount,
      collectionMethod,
    )}`,
    customerId,
    orderId,
    now,
  });
  await batch.commit();
  await Promise.all([
    sendPushToAudience({
      shopId: staffCtx.shopId,
      audience: "admin",
      title: collectionStatus === "pending"
        ? "Instant - payment pending"
        : "Instant - delivered",
      body: `${callerName} - ${summary} - ${collectionStatusLabel(
        collectionStatus,
        collectedAmount,
        collectionMethod,
      )}`,
      customerId,
      data: {
        type: collectionStatus === "pending"
          ? "dispatchPaymentPending"
          : "dispatchFulfilled",
        orderId,
        deliveryId: deliveryRef.id,
      },
    }),
    sendPushToAudience({
      shopId: staffCtx.shopId,
      audience: "customer",
      title: "Water delivered today",
      body: `${summary} delivered to your address. Amount Rs.${Math.round(totals.totalAmount)} added to your account.`,
      customerId,
      data: {
        type: "deliveryRecorded",
        orderId,
        deliveryId: deliveryRef.id,
      },
    }),
  ]);

  return {
    order: orderPayload(orderId, {
      ...order,
      fulfilledAt: new Date(),
      fulfilledBy,
      collectionStatus,
      collectedAmount: collectionStatus === "collected" ? collectedAmount : 0,
      collectionMethod: collectionStatus === "collected" ? collectionMethod : "",
      collectionRecordedBy,
    }),
    delivery: deliveryPayload(deliveryRef.id, {
      ...delivery,
      driverId,
      createdAt: new Date(),
    }),
  };
});

exports.updateWalkInDispatch = onCall(callableOptions, async (request) => {
  const adminCtx = await requireAdmin(request.auth);
  const orderId = cleanText(request.data.orderId, "Order id");
  const action = cleanText(request.data.action, "Action");
  const orderRef = db
    .collection("shops")
    .doc(adminCtx.shopId)
    .collection("orders")
    .doc(orderId);
  const orderSnap = await orderRef.get();
  const order = orderSnap.data();
  if (!order || order.source !== "phoneCall") {
    throw new HttpsError("failed-precondition", "Walk-in dispatch not found.");
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const updates = { updatedAt: now };
  let responseOrder = { ...order };

  if (action === "cancel") {
    if (order.fulfilledAt) {
      throw new HttpsError(
        "failed-precondition",
        "Already delivered — cannot cancel.",
      );
    }
    updates.status = "cancelled";
    responseOrder.status = "cancelled";
  } else if (action === "updateNote") {
    updates.adminDispatchNote = String(request.data.adminNote || "").trim();
    responseOrder.adminDispatchNote = updates.adminDispatchNote;
  } else if (action === "markDelivered") {
    if (order.fulfilledAt) {
      throw new HttpsError("failed-precondition", "Already marked delivered.");
    }
    const collectionStatus = cleanCollectionStatus(
      request.data.collectionStatus || "waived",
    );
    const collectedAmount = collectionStatus === "collected"
      ? cleanAmount(request.data.collectedAmount)
      : 0;
    const collectionMethod = collectionStatus === "collected"
      ? cleanPaymentMethod(request.data.collectionMethod)
      : "";
    updates.fulfilledAt = now;
    updates.fulfilledBy = "admin";
    updates.collectionStatus = collectionStatus;
    updates.collectedAmount = collectionStatus === "collected"
      ? collectedAmount
      : 0;
    updates.collectionMethod = collectionStatus === "collected"
      ? collectionMethod
      : "";
    updates.collectionRecordedBy = "admin";
    responseOrder.fulfilledAt = new Date();
    responseOrder.fulfilledBy = "admin";
    responseOrder.collectionStatus = collectionStatus;
    responseOrder.collectedAmount = updates.collectedAmount;
    responseOrder.collectionMethod = updates.collectionMethod;
    responseOrder.collectionRecordedBy = "admin";

    const callerName = order.walkInContact?.name || "Customer";
    const notifyBatch = db.batch();
    notifyBatch.set(orderRef, updates, { merge: true });
    appendOrderNotification({
      batch: notifyBatch,
      shopId: adminCtx.shopId,
      type: collectionStatus === "pending"
        ? "dispatchPaymentPending"
        : "dispatchFulfilled",
      audience: "admin",
      title: "Instant · admin confirmed",
      body: `${callerName} — ${collectionStatusLabel(
        collectionStatus,
        collectedAmount,
        collectionMethod,
      )}`,
      customerId: order.customerId,
      orderId,
      now,
    });
    await notifyBatch.commit();
    await sendPushToAudience({
      shopId: adminCtx.shopId,
      audience: "admin",
      title: "Instant - admin confirmed",
      body: `${callerName} - ${collectionStatusLabel(
        collectionStatus,
        collectedAmount,
        collectionMethod,
      )}`,
      customerId: order.customerId,
      data: {
        type: collectionStatus === "pending"
          ? "dispatchPaymentPending"
          : "dispatchFulfilled",
        orderId,
      },
    });
    return orderPayload(orderId, responseOrder);
  } else if (action === "updateCollection") {
    if (!order.fulfilledAt) {
      throw new HttpsError(
        "failed-precondition",
        "Mark delivered before updating payment.",
      );
    }
    const collectionStatus = cleanCollectionStatus(request.data.collectionStatus);
    const collectedAmount = collectionStatus === "collected"
      ? cleanAmount(request.data.collectedAmount)
      : 0;
    const collectionMethod = collectionStatus === "collected"
      ? cleanPaymentMethod(request.data.collectionMethod)
      : "";
    updates.collectionStatus = collectionStatus;
    updates.collectedAmount = collectionStatus === "collected"
      ? collectedAmount
      : 0;
    updates.collectionMethod = collectionStatus === "collected"
      ? collectionMethod
      : "";
    updates.collectionRecordedBy = "admin";
    responseOrder.collectionStatus = collectionStatus;
    responseOrder.collectedAmount = updates.collectedAmount;
    responseOrder.collectionMethod = updates.collectionMethod;
    responseOrder.collectionRecordedBy = "admin";
  } else if (action === "reassignDriver") {
    if (order.fulfilledAt) {
      throw new HttpsError(
        "failed-precondition",
        "Already delivered — cannot reassign driver.",
      );
    }
    if (order.status !== "accepted") {
      throw new HttpsError(
        "failed-precondition",
        "Only active orders can be reassigned.",
      );
    }
    const newDriverId = cleanText(request.data.driverId, "Driver");
    const { driver } = await getDriverForAdmin(adminCtx, newDriverId);
    if (driver.active === false) {
      throw new HttpsError("failed-precondition", "Selected driver is inactive.");
    }
    updates.driverId = newDriverId;
    responseOrder.driverId = newDriverId;

    const callerName = order.walkInContact?.name || "Customer";
    const batch = db.batch();
    batch.set(orderRef, updates, { merge: true });
    appendOrderNotification({
      batch,
      shopId: adminCtx.shopId,
      type: "orderAccepted",
      audience: "driver",
      title: "Instant delivery",
      body: `${callerName} · ${dispatchItemsSummary(order.lineItems || [])}`,
      customerId: order.customerId,
      orderId,
      driverId: newDriverId,
      now,
    });
    await batch.commit();
    await sendPushToAudience({
      shopId: adminCtx.shopId,
      audience: "driver",
      title: "Instant delivery",
      body: `${callerName} - ${dispatchItemsSummary(order.lineItems || [])}`,
      customerId: order.customerId,
      driverId: newDriverId,
      data: {
        type: "orderAccepted",
        orderId,
      },
    });
    return orderPayload(orderId, responseOrder);
  } else {
    throw new HttpsError("invalid-argument", "Unsupported action.");
  }

  await orderRef.set(updates, { merge: true });
  return orderPayload(orderId, responseOrder);
});

exports.getShopSubscription = onCall(callableOptions, async (request) => {
  const adminCtx = await requireAdmin(request.auth);
  const shopRef = db.collection("shops").doc(adminCtx.shopId);
  const shopSnap = await shopRef.get();
  const shop = shopSnap.data();
  if (!shop) {
    throw new HttpsError("not-found", "Shop not found.");
  }
  const fresh = await ensureShopSubscriptionFresh(shopRef, shop);
  return shopPayload(shopRef.id, fresh);
});

exports.activateShopSubscription = onCall(callableOptions, async (request) => {
  const adminCtx = await requireAdmin(request.auth);
  const planId = cleanText(request.data.planId, "Plan");
  const plan = SUBSCRIPTION_PLANS[planId];
  if (!plan) {
    throw new HttpsError("invalid-argument", "Choose a valid subscription plan.");
  }
  const billingCycle = request.data.billingCycle === "annual"
    ? "annual"
    : "monthly";
  const shopRef = db.collection("shops").doc(adminCtx.shopId);
  const shopSnap = await shopRef.get();
  const shop = shopSnap.data();
  if (!shop) {
    throw new HttpsError("not-found", "Shop not found.");
  }

  const now = new Date();
  const periodEnd = billingCycle === "annual"
    ? addMonths(now, 12)
    : addMonths(now, 1);
  const updates = {
    subscriptionStatus: "active",
    planId,
    billingCycle,
    subscriptionStartedAt: admin.firestore.FieldValue.serverTimestamp(),
    currentPeriodEndsAt: timestampFromDate(periodEnd),
    graceEndsAt: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await shopRef.set(updates, { merge: true });
  const updatedSnap = await shopRef.get();
  return shopPayload(shopRef.id, updatedSnap.data() || {});
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
