/**
 * API smoke + basic load test.
 * Usage: node scripts/smoke-test.js [--load]
 * Requires: MongoDB running, server on PORT (default 3000), seed data.
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const http = require('http');
const https = require('https');

const BASE = process.env.SMOKE_BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
const RUN_LOAD = process.argv.includes('--load');

let passed = 0;
let failed = 0;

function request(method, path, { body, token } = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE);
    const lib = url.protocol === 'https:' ? https : http;
    const payload = body ? JSON.stringify(body) : null;
    const req = lib.request(
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

async function assert(name, fn) {
  try {
    await fn();
    passed += 1;
    console.log(`  ✓ ${name}`);
  } catch (err) {
    failed += 1;
    console.error(`  ✗ ${name}: ${err.message}`);
  }
}

async function loadTestAuthed(path, token, concurrency = 20, total = 200) {
  console.log(`\nLoad test (auth): ${total} requests @ ${concurrency} concurrent → ${path}`);
  const start = Date.now();
  let ok = 0;
  let errors = 0;
  let idx = 0;

  async function worker() {
    while (idx < total) {
      idx += 1;
      try {
        const res = await request('GET', path, { token });
        if (res.status === 200) ok += 1;
        else errors += 1;
      } catch {
        errors += 1;
      }
    }
  }

  await Promise.all(Array.from({ length: concurrency }, () => worker()));
  const ms = Date.now() - start;
  console.log(`  ${ok}/${total} OK, ${errors} errors, ${ms}ms (${Math.round((ok / ms) * 1000)} req/s)`);
  if (errors > total * 0.05) throw new Error(`Load test error rate too high: ${errors}/${total}`);
}

async function loadTest(path, concurrency = 50, total = 500) {
  console.log(`\nLoad test: ${total} requests @ ${concurrency} concurrent → ${path}`);
  const start = Date.now();
  let ok = 0;
  let errors = 0;
  let idx = 0;

  async function worker() {
    while (idx < total) {
      idx += 1;
      try {
        const res = await request('GET', path);
        if (res.status === 200) ok += 1;
        else errors += 1;
      } catch {
        errors += 1;
      }
    }
  }

  await Promise.all(Array.from({ length: concurrency }, () => worker()));
  const ms = Date.now() - start;
  console.log(`  ${ok}/${total} OK, ${errors} errors, ${ms}ms (${Math.round((ok / ms) * 1000)} req/s)`);
  if (errors > total * 0.05) throw new Error(`Load test error rate too high: ${errors}/${total}`);
}

async function main() {
  console.log(`Smoke test → ${BASE}\n`);

  let adminToken;
  let customerToken;
  let placedOrderId;

  await assert('GET /health', async () => {
    const res = await request('GET', '/health');
    if (res.status !== 200 || res.json.status !== 'ok') {
      throw new Error(`Unexpected: ${res.status} ${JSON.stringify(res.json)}`);
    }
  });

  await assert('POST /api/auth/login (admin)', async () => {
    const res = await request('POST', '/api/auth/login', {
      body: { email: 'admin@srisai.com', password: 'admin123' },
    });
    if (res.status !== 200 || !res.json.token) throw new Error(JSON.stringify(res.json));
    adminToken = res.json.token;
  });

  await assert('GET /api/shop (admin)', async () => {
    const res = await request('GET', '/api/shop', { token: adminToken });
    if (res.status !== 200 || !res.json.shop) throw new Error(JSON.stringify(res.json));
  });

  await assert('GET /api/orders (admin)', async () => {
    const res = await request('GET', '/api/orders', { token: adminToken });
    if (res.status !== 200) throw new Error(JSON.stringify(res.json));
  });

  await assert('GET /api/reports/dashboard', async () => {
    const res = await request('GET', '/api/reports/dashboard', { token: adminToken });
    if (res.status !== 200 || !res.json.stats) throw new Error(JSON.stringify(res.json));
  });

  await assert('GET /api/notifications (admin)', async () => {
    const res = await request('GET', '/api/notifications', { token: adminToken });
    if (res.status !== 200) throw new Error(JSON.stringify(res.json));
  });

  await assert('POST /api/auth/customer/request-otp', async () => {
    const res = await request('POST', '/api/auth/customer/request-otp', {
      body: { phone: '9999999999' },
    });
    if (res.status !== 200) throw new Error(JSON.stringify(res.json));
  });

  await assert('POST /api/auth/customer/verify-otp', async () => {
    const res = await request('POST', '/api/auth/customer/verify-otp', {
      body: { phone: '9999999999', otp: process.env.CUSTOMER_DEMO_OTP || '123456' },
    });
    if (res.status !== 200 || !res.json.token) throw new Error(JSON.stringify(res.json));
    customerToken = res.json.token;
  });

  await assert('GET /api/orders/customer/mine', async () => {
    const res = await request('GET', '/api/orders/customer/mine', { token: customerToken });
    if (res.status !== 200) throw new Error(JSON.stringify(res.json));
  });

  await assert('POST /api/orders (customer place order)', async () => {
    const res = await request('POST', '/api/orders', {
      token: customerToken,
      body: {
        shopId: 'shop-1',
        normalQty: 2,
        coolQty: 1,
        customerNote: 'Smoke test order',
      },
    });
    if (res.status !== 201 || !res.json.order?.orderId) throw new Error(JSON.stringify(res.json));
    if (!res.json.order.totalAmount || res.json.order.totalAmount <= 0) {
      throw new Error(`Expected totalAmount > 0: ${JSON.stringify(res.json.order)}`);
    }
    placedOrderId = res.json.order.orderId;
  });

  await assert('PATCH /api/orders/:id/accept (admin)', async () => {
    const res = await request('PATCH', `/api/orders/${placedOrderId}/accept`, {
      token: adminToken,
      body: { adminNote: 'Accepted (smoke)' },
    });
    if (res.status !== 200) throw new Error(JSON.stringify(res.json));
  });

  await assert('GET /api/notifications (customer)', async () => {
    const res = await request('GET', '/api/notifications', { token: customerToken });
    if (res.status !== 200) throw new Error(JSON.stringify(res.json));
  });

  if (RUN_LOAD) {
    await loadTest('/health', 50, 500);
    if (adminToken) {
      await loadTestAuthed('/api/orders?limit=10', adminToken, 20, 200);
    }
  }

  console.log(`\n${passed} passed, ${failed} failed`);
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error('Smoke test crashed:', err);
  process.exit(1);
});
