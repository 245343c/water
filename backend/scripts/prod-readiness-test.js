/**
 * Production readiness integration test — admin, driver, customer flows + DB checks.
 * Usage: node scripts/prod-readiness-test.js
 *
 * Notes:
 * - Works with clean seed (no demo customers).
 * - OTP exposure is allowed only when APP_ENV=local and OTP_MODE=local.
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');
const http = require('http');

const BASE = process.env.SMOKE_BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
const SHOP_ID = 'shop-1';

const Customer = require('../src/models/Customer');
const Order = require('../src/models/Order');
const Delivery = require('../src/models/Delivery');
const Product = require('../src/models/Product');
const Driver = require('../src/models/Driver');
const CashCollection = require('../src/models/CashCollection');

const issues = [];
const passes = [];

const appEnv = String(process.env.APP_ENV || process.env.NODE_ENV || 'local').toLowerCase();
const otpMode = String(process.env.OTP_MODE || (appEnv === 'production' ? 'sms' : 'local')).toLowerCase();
const allowOtpInResponse = appEnv !== 'production' && otpMode === 'local';

function issue(severity, area, message, detail) {
  issues.push({ severity, area, message, detail: detail || null });
  console.log(`  ✗ [${severity}] ${area}: ${message}${detail ? ` — ${detail}` : ''}`);
}

function pass(name) {
  passes.push(name);
  console.log(`  ✓ ${name}`);
}

function request(method, path, { body, token } = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE);
    const payload = body ? JSON.stringify(body) : null;
    const req = http.request(
      url,
      {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
          ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
        },
      },
      (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end', () => {
          let json = {};
          try {
            json = data ? JSON.parse(data) : {};
          } catch {
            json = { raw: data };
          }
          resolve({ status: res.statusCode, json });
        });
      },
    );
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function main() {
  console.log(`\n=== Production Readiness Test → ${BASE} ===`);
  console.log(`APP_ENV=${appEnv} OTP_MODE=${otpMode}\n`);

  let adminToken;
  let driverToken;
  let customerToken;
  let customerId;
  let customerPhone;
  let orderId;
  let productId;
  let deliveryId;

  // Health
  try {
    const res = await request('GET', '/health');
    if (res.status !== 200) throw new Error(`status ${res.status}`);
    pass('Server health OK');
  } catch (e) {
    issue('BLOCKER', 'Server', 'Backend not reachable', e.message);
    printSummary();
    process.exit(1);
  }

  await mongoose.connect(process.env.MONGO_URI);
  console.log('  (MongoDB connected for field verification)\n');

  // Admin login
  console.log('── Admin ──');
  try {
    const res = await request('POST', '/api/auth/login', {
      body: { email: 'admin@srisai.com', password: 'admin123' },
    });
    if (res.status !== 200 || !res.json.token) throw new Error(JSON.stringify(res.json));
    adminToken = res.json.token;
    pass('Admin login');
  } catch (e) {
    issue('BLOCKER', 'Admin', 'Login failed', e.message);
  }

  // Create customer
  customerPhone = `9876${String(Date.now()).slice(-6)}`;
  try {
    const res = await request('POST', '/api/customers', {
      token: adminToken,
      body: {
        name: 'Prod Test Customer',
        phone: customerPhone,
        address: 'Test Street, Rajahmundry',
        routeId: 'route-1',
      },
    });
    if (res.status !== 201) throw new Error(JSON.stringify(res.json));
    customerId = res.json.customer.customerId;
    pass(`Admin create customer (${customerId})`);

    const dbCust = await Customer.findOne({ customerId });
    if (!dbCust) issue('HIGH', 'Admin/DB', 'Customer not in MongoDB after create');
    else if (dbCust.routeId !== 'route-1') issue('HIGH', 'Admin/DB', 'Customer routeId not saved', dbCust.routeId);
    else pass('DB: customer routeId saved');
  } catch (e) {
    issue('BLOCKER', 'Admin', 'Create customer failed', e.message);
  }

  // Create product (API contract: name/category/price)
  try {
    const res = await request('POST', '/api/products', {
      token: adminToken,
      body: {
        name: 'Test Bottle 20L',
        category: 'bottle',
        price: 50,
        variantLabel: '20L',
        imageUrl: null,
      },
    });
    if (res.status !== 201) throw new Error(JSON.stringify(res.json));
    productId = res.json.product.productId;
    pass('Admin create product');

    const dbProd = await Product.findOne({ productId });
    if (!dbProd) issue('HIGH', 'Admin/DB', 'Product not in MongoDB');
    else pass('DB: product saved');
  } catch (e) {
    issue('HIGH', 'Admin', 'Create product failed', e.message);
  }

  // Shop settings update (API contract: PUT /api/shop)
  try {
    const res = await request('PUT', '/api/shop', {
      token: adminToken,
      body: { homeDeliveryAvailable: true, normalCanPrice: 22, coolCanPrice: 32 },
    });
    if (res.status !== 200) throw new Error(JSON.stringify(res.json));
    pass('Admin update shop settings');
  } catch (e) {
    issue('HIGH', 'Admin', 'Shop settings update failed', e.message);
  }

  // Driver login
  console.log('\n── Driver ──');
  try {
    const res = await request('POST', '/api/auth/login', {
      body: { email: 'driver@srisai.com', password: 'driver123' },
    });
    if (res.status !== 200 || !res.json.token) throw new Error(JSON.stringify(res.json));
    driverToken = res.json.token;
    pass('Driver login');
  } catch (e) {
    issue('BLOCKER', 'Driver', 'Login failed', e.message);
  }

  // Driver availability
  try {
    const res = await request('PATCH', '/api/drivers/me/availability', {
      token: driverToken,
      body: { active: false },
    });
    if (res.status !== 200) throw new Error(JSON.stringify(res.json));
    const dbDriver = await Driver.findOne({ uid: 'user-driver-1' });
    if (dbDriver && dbDriver.active === false) pass('DB: driver availability saved (inactive)');
    else issue('MEDIUM', 'Driver/DB', 'Driver active flag not updated in DB');

    await request('PATCH', '/api/drivers/me/availability', {
      token: driverToken,
      body: { active: true },
    });
    pass('Driver toggle availability');
  } catch (e) {
    issue('HIGH', 'Driver', 'Availability toggle failed', e.message);
  }

  // Customer OTP login
  console.log('\n── Customer ──');
  try {
    const otpRes = await request('POST', '/api/auth/customer/request-otp', {
      body: { phone: customerPhone },
    });
    if (otpRes.status !== 200) throw new Error(JSON.stringify(otpRes.json));

    const otp = otpRes.json.otp || process.env.CUSTOMER_DEMO_OTP || '123456';
    const verifyRes = await request('POST', '/api/auth/customer/verify-otp', {
      body: { phone: customerPhone, otp },
    });
    if (verifyRes.status !== 200 || !verifyRes.json.token) {
      throw new Error(JSON.stringify(verifyRes.json));
    }
    customerToken = verifyRes.json.token;
    pass('Customer OTP login (registered phone)');

    if (otpRes.json.otp) {
      if (allowOtpInResponse) {
        issue('MEDIUM', 'Security', 'OTP returned in API response (allowed only for local dev)');
      } else {
        issue('BLOCKER', 'Security', 'OTP returned in API response (must never happen outside local dev)');
      }
    }
  } catch (e) {
    issue('BLOCKER', 'Customer', 'OTP login failed', e.message);
  }

  // Place order
  try {
    const res = await request('POST', '/api/orders', {
      token: customerToken,
      body: { shopId: SHOP_ID, normalQty: 2, coolQty: 1, customerNote: 'Prod test order' },
    });
    if (res.status !== 201) throw new Error(JSON.stringify(res.json));
    orderId = res.json.order.orderId;
    pass('Customer place order');

    const dbOrder = await Order.findOne({ orderId });
    if (!dbOrder) issue('BLOCKER', 'Orders/DB', 'Order not in MongoDB');
    else if (dbOrder.orderStatus !== 'pending') issue('HIGH', 'Orders/DB', 'New order should be pending', dbOrder.orderStatus);
    else pass('DB: order status pending');
  } catch (e) {
    issue('BLOCKER', 'Customer', 'Place order failed', e.message);
  }

  // Admin accept + assign
  console.log('\n── Order workflow ──');
  try {
    const acceptRes = await request('PATCH', `/api/orders/${orderId}/accept`, {
      token: adminToken,
      body: { adminNote: 'Accepted' },
    });
    if (acceptRes.status !== 200) throw new Error(JSON.stringify(acceptRes.json));
    pass('Admin accept order');

    const assignRes = await request('PATCH', `/api/orders/${orderId}/assign`, {
      token: adminToken,
      body: { driverId: 'driver-1', driverName: 'Rajesh Kumar' },
    });
    if (assignRes.status !== 200) throw new Error(JSON.stringify(assignRes.json));
    pass('Admin assign driver');

    const dbOrder = await Order.findOne({ orderId });
    if (dbOrder?.orderStatus !== 'assigned') issue('HIGH', 'Orders/DB', 'Order should be assigned after assign', dbOrder?.orderStatus);
    else pass('DB: order status assigned');
  } catch (e) {
    issue('HIGH', 'Orders', 'Accept/assign failed', e.message);
  }

  // Driver record delivery with orderId
  try {
    const delRes = await request('POST', '/api/deliveries', {
      token: driverToken,
      body: {
        customerId,
        orderId,
        deliveryType: 'app_order_delivery',
        lines: [
          { kind: 'normalCan', label: 'Normal Can', quantity: 2, unitPrice: 22 },
          { kind: 'coolCan', label: 'Cool Can', quantity: 1, unitPrice: 32 },
        ],
      },
    });
    if (delRes.status !== 201) throw new Error(JSON.stringify(delRes.json));
    deliveryId = delRes.json.delivery.deliveryId;
    pass('Driver record delivery (linked to order)');

    const dbDel = await Delivery.findOne({ deliveryId });
    if (!dbDel?.orderId) issue('HIGH', 'Delivery/DB', 'Delivery orderId not saved');
    else pass('DB: delivery orderId saved');
  } catch (e) {
    issue('HIGH', 'Driver', 'Record delivery failed', e.message);
  }

  // Payment (may move pending → advanceCredit)
  console.log('\n── Payments ──');
  try {
    const res = await request('POST', '/api/cash', {
      token: adminToken,
      body: {
        customerId,
        amount: 100,
        paymentMethod: 'cash',
        notes: 'Prod test payment',
      },
    });
    if (res.status !== 201) throw new Error(JSON.stringify(res.json));
    pass('Admin record payment');

    const dbCust = await Customer.findOne({ customerId });
    if (!dbCust) issue('HIGH', 'Payments/DB', 'Customer missing for balance verification');
    else if (dbCust.totalPendingAmount < 0 || dbCust.advanceCredit < 0) {
      issue('HIGH', 'Payments/DB', 'Pending/advance must never be negative', JSON.stringify({
        pending: dbCust.totalPendingAmount,
        advance: dbCust.advanceCredit,
      }));
    } else {
      pass('DB: pending/advance non-negative');
    }

    const dbCash = await CashCollection.findOne({ customerId }).sort({ createdAt: -1 });
    if (!dbCash) issue('HIGH', 'Payments/DB', 'Payment not in MongoDB');
    else pass('DB: cash collection saved');
  } catch (e) {
    issue('HIGH', 'Payments', 'Record payment failed', e.message);
  }

  await mongoose.disconnect();
  printSummary();
  process.exit(issues.some((i) => i.severity === 'BLOCKER') ? 1 : 0);
}

function printSummary() {
  console.log('\n=== SUMMARY ===');
  console.log(`Passed: ${passes.length}`);
  console.log(`Issues: ${issues.length}`);
  const blockers = issues.filter((i) => i.severity === 'BLOCKER');
  const high = issues.filter((i) => i.severity === 'HIGH');
  const medium = issues.filter((i) => i.severity === 'MEDIUM');
  if (blockers.length) {
    console.log(`\nBLOCKERS (${blockers.length}):`);
    blockers.forEach((i) => console.log(`  - [${i.area}] ${i.message}`));
  }
  if (high.length) {
    console.log(`\nHIGH (${high.length}):`);
    high.forEach((i) => console.log(`  - [${i.area}] ${i.message}`));
  }
  if (medium.length) {
    console.log(`\nMEDIUM (${medium.length}):`);
    medium.forEach((i) => console.log(`  - [${i.area}] ${i.message}`));
  }
  console.log('');
}

main().catch((err) => {
  console.error('Test crashed:', err);
  process.exit(1);
});

