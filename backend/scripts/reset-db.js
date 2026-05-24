/**
 * Wipe all business data and start fresh. Keeps nothing — run seed.js after.
 * Run: node scripts/reset-db.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');
const User = require('../src/models/User');
const Shop = require('../src/models/Shop');
const Driver = require('../src/models/Driver');
const Customer = require('../src/models/Customer');
const DeliveryRoute = require('../src/models/DeliveryRoute');
const Order = require('../src/models/Order');
const Delivery = require('../src/models/Delivery');
const Notification = require('../src/models/Notification');
const Product = require('../src/models/Product');
const Promotion = require('../src/models/Promotion');
const MonthlyBill = require('../src/models/MonthlyBill');
const CashCollection = require('../src/models/CashCollection');
const OtpCode = require('../src/models/OtpCode');
const AuditLog = require('../src/models/AuditLog');

async function reset() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to MongoDB');
  console.log('Wiping all collections…');

  const results = await Promise.all([
    Order.deleteMany({}),
    Delivery.deleteMany({}),
    Notification.deleteMany({}),
    Customer.deleteMany({}),
    Product.deleteMany({}),
    Promotion.deleteMany({}),
    MonthlyBill.deleteMany({}),
    CashCollection.deleteMany({}),
    OtpCode.deleteMany({}),
    AuditLog.deleteMany({}),
    DeliveryRoute.deleteMany({}),
    Driver.deleteMany({}),
    User.deleteMany({}),
    Shop.deleteMany({}),
  ]);

  const total = results.reduce((sum, r) => sum + r.deletedCount, 0);
  console.log(`Removed ${total} document(s) across all collections.`);
  console.log('Database is empty. Run: npm run seed');
  await mongoose.disconnect();
}

reset().catch((err) => {
  console.error(err);
  process.exit(1);
});
