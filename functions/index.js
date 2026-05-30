"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const callableOptions = { invoker: "public" };

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
    driverId: data.driverId || null,
    date: date instanceof Date ? date.toISOString() : "",
    createdAt: createdAt instanceof Date ? createdAt.toISOString() : "",
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
  const customerId = cleanText(request.data.customerId, "Customer id");
  const date = cleanDate(request.data.date, "Delivery date");
  const lines = cleanDeliveryLines(request.data.lines);
  const totals = deliveryTotals(lines);

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
  await batch.commit();

  return deliveryPayload(deliveryRef.id, {
    ...delivery,
    createdAt: new Date(),
  });
});
